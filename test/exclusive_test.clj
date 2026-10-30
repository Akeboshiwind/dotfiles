(ns exclusive-test
  (:require [clojure.test :refer [deftest testing is]]
            [actions :as a]
            [actions.syn :as syn]
            [graph :as g]
            [manifest :as m]
            [outcome :as o]
            [plan :as p]
            [status :as s]
            [registry]
            [support]))

(def ^:private uv-facts
  {[:command "uv"] true
   [:uv :installed] #{"black" "ruff" "httpie"}
   [:manifest :declared] {:root "/home/dotfiles" :types {:uv/tool #{"black"}}}
   [:syn :pinned-root] "/home/dotfiles"})

(deftest uv-extras-test
  (testing "installed but undeclared uv tools are extras, sorted"
    (is (= [{:name "httpie"} {:name "ruff"}]
           (a/extras :uv/tool #{"black"} (support/facts-of uv-facts)))))
  (testing "no uv, no extras"
    (is (= [] (a/extras :uv/tool #{} (support/facts-of {[:command "uv"] false}))))))

(deftest bbin-extras-test
  (testing "installed but undeclared bbin scripts are extras"
    (is (= [{:name "neil"}]
           (a/extras :pkg/bbin #{"jet"} (support/facts-of {[:command "bbin"] true
                                                           [:bbin :installed] #{"jet" "neil"}})))))
  (testing "removing them runs bbin uninstall for each"
    (let [calls (atom [])]
      (with-redefs [a/exec! (fn [_ args] (swap! calls conj args) {:exit 0 :err nil})]
        (with-out-str (a/remove-extras! :pkg/bbin {} [{:name "neil"}] {})))
      (is (= [["bbin" "uninstall" "neil"]] @calls)))))

(deftest npm-extras-test
  (testing "undeclared global packages are extras; the ones node ships never are"
    (is (= [{:name "left-pad"}]
           (a/extras :pkg/npm #{"prettier"}
                     (support/facts-of {[:command "npm"] true
                                        [:npm :installed] #{"prettier" "left-pad" "npm" "corepack"}}))))))

(defn- mise-extras [installed global-tools]
  (a/extras :pkg/mise #{"node"}
            (support/facts-of {[:command "mise"] true
                               [:mise :installed] installed
                               [:mise :global-tools] global-tools})))

(defn- mise-removal-calls [extras]
  (let [calls (atom [])]
    (with-redefs [a/exec! (fn [_ args] (swap! calls conj args) {:exit 0 :err nil})]
      (with-out-str (doall (a/remove-extras! :pkg/mise {} extras {}))))
    @calls))

(deftest mise-extras-test
  (testing "installed but undeclared mise tools are extras"
    (is (= [{:name "python" :installed? true :requested? false}]
           (mise-extras {"node" #{"20"} "python" #{"3.12"}} #{"node"}))))

  (testing "a tool the global config requests but the manifest doesn't declare is an extra, installed or not"
    (is (= [{:name "deno" :installed? false :requested? true}
            {:name "python" :installed? true :requested? true}]
           (mise-extras {"node" #{"20"} "python" #{"3.12"}} #{"node" "python" "deno"}))))

  (testing "an installed extra is uninstalled"
    (is (= [["mise" "uninstall" "--all" "python"]]
           (mise-removal-calls [{:name "python" :installed? true :requested? false}]))))

  (testing "a requested extra loses its global request, keeping installs for the uninstall to decide"
    (is (= [["mise" "unuse" "--global" "--no-prune" "deno"]]
           (mise-removal-calls [{:name "deno" :installed? false :requested? true}]))))

  (testing "an extra that is both loses its request, then is uninstalled"
    (is (= [["mise" "unuse" "--global" "--no-prune" "python"]
            ["mise" "uninstall" "--all" "python"]]
           (mise-removal-calls [{:name "python" :installed? true :requested? true}])))))

(deftest mise-extras-queries-test
  (is (contains? (a/extras-queries :pkg/mise) [:mise :global-tools])))

(deftest mas-extras-test
  (testing "installed apps not declared by id are extras"
    (is (= [{:name "497799835" :label "Xcode"}]
           (a/extras :pkg/mas #{"904280696"}
                     (support/facts-of {[:command "mas"] true
                                        [:mas :installed] {904280696 "Things3" 497799835 "Xcode"}})))))
  (testing "removing them runs mas uninstall by id"
    (let [calls (atom [])]
      (with-redefs [a/exec! (fn [_ args] (swap! calls conj args) {:exit 0 :err nil})]
        (with-out-str (a/remove-extras! :pkg/mas {} [{:name "497799835" :label "Xcode"}] {})))
      (is (= [["mas" "uninstall" "497799835"]] @calls)))))

(deftest exclusive-check-test
  (testing "extras are the node's drift"
    (let [result (a/check :syn/exclusive :uv/tool {} (support/facts-of uv-facts))]
      (is (= :extra (:kind result)))
      (is (= [{:name "httpie"} {:name "ruff"}] (:extras result)))
      (is (= "/home/dotfiles" (get-in result [:source :root])))))

  (testing "nothing extra is satisfied"
    (is (o/satisfied? (a/check :syn/exclusive :uv/tool {}
                               (support/facts-of (assoc uv-facts [:uv :installed] #{"black"}))))))

  (testing "no pin yet is a conflict, never a removal"
    (is (o/conflict? (a/check :syn/exclusive :uv/tool {}
                              (support/facts-of (assoc uv-facts [:syn :pinned-root] nil))))))

  (testing "a manifest read from another root is a conflict"
    (let [result (a/check :syn/exclusive :uv/tool {}
                          (support/facts-of (assoc uv-facts [:syn :pinned-root] "/elsewhere")))]
      (is (o/conflict? result))
      (is (re-find #"not the pinned root /elsewhere" (:message result))))))

(deftest removable-test
  (testing "only extras the plan showed that are still extra"
    (is (= [{:name "ruff"}]
           (syn/removable [{:name "ruff"} {:name "gone"}] [{:name "ruff"} {:name "new"}])))))

(defn- apply-uv [shown]
  (let [removed (atom nil)
        facts (assoc (support/facts-of uv-facts)
                     [:plan :check [:syn/exclusive :uv/tool]] {:at 0 :value {:extras shown}})]
    (with-redefs [a/remove-extras! (fn [_ _ extras _] (reset! removed extras) [])]
      {:results (with-out-str (a/install! :syn/exclusive {} {:uv/tool {}} facts))
       :removed @removed})))

(deftest exclusive-install-test
  (testing "removes what the plan showed that is still extra"
    (is (= [{:name "ruff"}] (:removed (apply-uv [{:name "ruff"}])))))
  (testing "something the plan didn't show is left alone"
    (is (= [{:name "ruff"}] (:removed (apply-uv [{:name "ruff"} {:name "gone"}])))))
  (testing "nothing the plan showed is still extra: nothing removed"
    (let [{:keys [results removed]} (apply-uv [{:name "gone"}])]
      (is (nil? removed))
      (is (re-find #"none of the extras the plan showed" results)))))

(defn- plugin [type step] {:step step :source nil :plugin type})
(defn- module [source step] {:step step :source source})

(deftest plugin-fragments-test
  (testing "every manager that defines extras declares itself exclusive"
    (is (= #{:pkg/brew :pkg/npm :pkg/mise :pkg/mas :uv/tool :pkg/bbin}
           (set (keys (apply merge (map (comp :syn/exclusive :step) (m/plugin-entries)))))))))

(deftest merge-layers-test
  (testing "an exclusive manager becomes a node that runs after its installs"
    (is (= {:uv/tool {:dep/requires #{[:complete :uv/tool]}}}
           (:syn/exclusive (:merged (p/merge-layers [(plugin :uv/tool {:syn/exclusive {:uv/tool {}}})]))))))

  (testing "the manifest opts a manager out with false"
    (let [{:keys [merged errors]} (p/merge-layers [(module "cfg/x" {:syn/exclusive {:pkg/mas false}})
                                                   (plugin :pkg/mas {:syn/exclusive {:pkg/mas {}}})])]
      (is (nil? (:syn/exclusive merged)))
      (is (empty? errors) "replacing a plugin's declaration is not a duplicate")))

  (testing "a manifest declaration of the same item replaces the plugin's"
    (is (= {:jq {:head true}}
           (:pkg/brew (:merged (p/merge-layers [(module "cfg/x" {:pkg/brew {:jq {:head true}}})
                                                (plugin :pkg/jq {:pkg/brew {:jq {}}})]))))))

  (testing "duplicates within the manifest are still errors"
    (is (= 1 (count (:errors (p/merge-layers [(module "cfg/a" {:pkg/brew {:jq {}}})
                                              (module "cfg/b" {:pkg/brew {:jq {}}})]))))))

  (testing "duplicates between plugins are errors, labelled by plugin"
    (is (= ["plugin pkg/a" "plugin pkg/b"]
           (:sources (first (:errors (p/merge-layers [(plugin :pkg/a {:pkg/brew {:jq {}}})
                                                      (plugin :pkg/b {:pkg/brew {:jq {}}})])))))))

  (testing "origin names the plugin behind each declaration the manifest didn't replace"
    (is (= {[:syn/exclusive :pkg/brew] :pkg/brew}
           (:origin (p/merge-layers [(module "cfg/x" {:pkg/brew {:jq {}}})
                                     (plugin :pkg/brew {:syn/exclusive {:pkg/brew {}}})
                                     (plugin :pkg/jq {:pkg/brew {:jq {}}})])))))

  (testing "anything but a map or false is rejected"
    (is (thrown? clojure.lang.ExceptionInfo
                 (p/merge-layers [(module "cfg/x" {:syn/exclusive {:pkg/brew true}})])))))

(deftest manifest-lines-test
  (testing "plugin entries are marked; options show only for :syn/exclusive"
    (is (= ["pkg/brew" "  :jq" "syn/exclusive" "  :pkg/brew {} ; from plugin pkg/brew"]
           (s/manifest-lines {:pkg/brew {:jq {:secret "x"}}
                              :syn/exclusive {:pkg/brew {:dep/requires #{[:complete :pkg/brew]}}}}
                             {[:syn/exclusive :pkg/brew] :pkg/brew})))))

(deftest exclusive-scope-test
  (testing "a scope on a manager includes its exclusive node; other scopes don't"
    (let [plan {:uv/tool {:black {}}
                :fs/symlink {"~/.x" "/src/x"}
                :syn/exclusive {:uv/tool {:dep/requires #{[:complete :uv/tool]}}}}
          order (g/topological-sort plan)]
      (is (some #{[:syn/exclusive :uv/tool]} (g/filter-order plan order :uv/tool)))
      (is (not-any? #{[:syn/exclusive :uv/tool]} (g/filter-order plan order :fs/symlink))))))
