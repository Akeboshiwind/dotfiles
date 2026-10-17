(ns exclusive-test
  (:require [clojure.test :refer [deftest testing is]]
            [actions :as a]
            [actions.syn :as syn]
            [display :as d]
            [graph :as g]
            [manifest :as m]
            [outcome :as o]
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

(defn- apply-uv [{:keys [tty? answer shown]}]
  (let [removed (atom nil)
        facts (assoc (support/facts-of uv-facts)
                     [:plan :check [:syn/exclusive :uv/tool]] {:at 0 :value {:extras shown}})]
    (with-redefs [d/tty? (constantly tty?)
                  read-line (constantly answer)
                  a/remove-extras! (fn [_ _ extras _] (reset! removed extras) [])]
      {:results (with-out-str (a/install! :syn/exclusive {} {:uv/tool {}} facts))
       :removed @removed})))

(deftest exclusive-install-test
  (testing "removes only what the plan showed, after confirmation at a terminal"
    (is (= [{:name "ruff"}]
           (:removed (apply-uv {:tty? true :answer "y" :shown [{:name "ruff"}]})))))
  (testing "without a terminal, nothing is removed"
    (let [{:keys [results removed]} (apply-uv {:tty? false :answer "y" :shown [{:name "ruff"}]})]
      (is (nil? removed))
      (is (re-find #"interactive terminal" results))))
  (testing "declining removes nothing"
    (is (nil? (:removed (apply-uv {:tty? true :answer "n" :shown [{:name "ruff"}]}))))))

(deftest exclusive-entry-test
  (testing "one node per exclusive manager, after that manager's installs"
    (is (= {:syn/exclusive {:uv/tool {:dep/requires #{[:complete :uv/tool]}}}}
           (:step (m/exclusive-entry #{:uv/tool})))))
  (testing "nothing declared exclusive adds nothing"
    (is (nil? (m/exclusive-entry nil))))
  (testing "anything but a set is rejected"
    (is (thrown? clojure.lang.ExceptionInfo (m/exclusive-entry {:uv/tool {}})))))

(deftest exclusive-scope-test
  (testing "a scope on a manager includes its exclusive node; other scopes don't"
    (let [plan {:uv/tool {:black {}}
                :fs/symlink {"~/.x" "/src/x"}
                :syn/exclusive {:uv/tool {:dep/requires #{[:complete :uv/tool]}}}}
          order (g/topological-sort plan)]
      (is (some #{[:syn/exclusive :uv/tool]} (g/filter-order plan order :uv/tool)))
      (is (not-any? #{[:syn/exclusive :uv/tool]} (g/filter-order plan order :fs/symlink))))))
