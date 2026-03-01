(ns orphan-test
  (:require [clojure.test :refer [deftest testing is]]
            [clojure.string :as str]
            [actions :as a]
            [actions.brew :as brew]
            [actions.bbin :as bbin]
            [actions.mise :as mise]
            [actions.mas :as mas]
            [graph :as g]
            [plan :as p]
            ;; Load action impls
            [execute]))

;; =============================================================================
;; brew deps-graph parsing
;; =============================================================================

(deftest deps-graph-test
  (testing "parses brew deps --installed output into adjacency map"
    (let [output "neovim: gettext libuv luajit luv msgpack tree-sitter unibilium\nripgrep: pcre2\ngit: gettext pcre2"]
      (is (= {"neovim" #{"gettext" "libuv" "luajit" "luv" "msgpack" "tree-sitter" "unibilium"}
              "ripgrep" #{"pcre2"}
              "git" #{"gettext" "pcre2"}}
             (brew/parse-deps-graph output)))))

  (testing "empty output returns empty map"
    (is (= {} (brew/parse-deps-graph ""))))

  (testing "package with no deps returns empty set"
    (is (= {"wget" #{}}
           (brew/parse-deps-graph "wget:")))))

;; =============================================================================
;; transitive deps closure
;; =============================================================================

(deftest transitive-deps-of-test
  (testing "computes transitive closure of declared packages"
    (let [graph {"neovim" #{"luajit" "gettext"}
                 "luajit" #{"readline"}
                 "git" #{"pcre2" "gettext"}
                 "pcre2" #{}
                 "gettext" #{}
                 "readline" #{}}]
      ;; declared: neovim, git
      ;; neovim -> luajit, gettext; luajit -> readline
      ;; git -> pcre2, gettext
      ;; closure = luajit gettext readline pcre2
      (is (= #{"luajit" "gettext" "readline" "pcre2"}
             (brew/transitive-deps-of #{"neovim" "git"} graph)))))

  (testing "empty declared returns empty deps"
    (is (= #{} (brew/transitive-deps-of #{} {"a" #{"b"}}))))

  (testing "declared package not in graph returns empty deps"
    (is (= #{} (brew/transitive-deps-of #{"unknown"} {"a" #{"b"}})))))

;; =============================================================================
;; orphans — per-action orphan detection
;; =============================================================================

(deftest brew-orphans-test
  (testing "formula not in manifest is orphaned"
    (let [result (brew/orphans {:formulae #{"neovim" "ripgrep" "wget"} :casks #{}}
                               {:neovim {} :ripgrep {}})]
      (is (= {"wget" {}} result))))

  (testing "only leaves are candidates, so no false positives"
    (let [result (brew/orphans {:formulae #{"neovim"} :casks #{}}
                               {:neovim {}})]
      (is (empty? result))))

  (testing "cask not in manifest is orphaned"
    (let [result (brew/orphans {:formulae #{} :casks #{"firefox" "slack"}}
                               {:firefox {:cask true}})]
      (is (= {"slack" {}} result))))

  (testing "no orphans returns empty"
    (let [result (brew/orphans {:formulae #{"neovim" "ripgrep"} :casks #{}}
                               {:neovim {} :ripgrep {}})]
      (is (empty? result))))

  (testing "tap-qualified: installed full-name matched by manifest short name"
    (let [result (brew/orphans {:formulae #{"babashka/brew/bbin"} :casks #{}}
                               {:bbin {}})]
      (is (empty? result))))

  (testing "tap-qualified: manifest uses full-name string key"
    (let [result (brew/orphans {:formulae #{"babashka/brew/bbin" "borkdude/brew/babashka"} :casks #{}}
                               {"babashka/brew/bbin" {} "borkdude/brew/babashka" {}})]
      (is (empty? result))))

  (testing "tap-qualified: mix of string and keyword keys"
    (let [result (brew/orphans {:formulae #{"babashka/brew/bbin" "neovim" "wget"} :casks #{}}
                               {"babashka/brew/bbin" {} :neovim {}})]
      (is (= {"wget" {}} result)))))

(deftest bbin-orphans-test
  (testing "script not in manifest is orphaned"
    (is (= {:neil {}} (bbin/orphans #{"jet" "neil"} {:jet {}}))))

  (testing "no orphans"
    (is (empty? (bbin/orphans #{"jet"} {:jet {}})))))

(deftest mise-orphans-test
  (testing "tool not in manifest is orphaned"
    (is (= {:python {}} (mise/orphans {"node" #{"20"} "python" #{"3.12"}} {:node {:version "20"}}))))

  (testing "no orphans"
    (is (empty? (mise/orphans {"node" #{"20"}} {:node {:version "20"}})))))

(deftest mas-orphans-test
  (testing "app not in manifest is orphaned"
    (is (= {497799835 {:name "Xcode"}} (mas/orphans {904280696 "Things3" 497799835 "Xcode"} {:things3 904280696}))))

  (testing "no orphans"
    (is (empty? (mas/orphans {904280696 "Things3"} {:things3 904280696})))))

;; =============================================================================
;; Uninstall action implementations
;; =============================================================================

(defn- mock-exec!
  "Returns a mock exec! fn that tracks calls in `calls` atom."
  [calls]
  (fn [opts args]
    (swap! calls conj args)
    {:exit 0 :err nil}))

(deftest brew-uninstall-action-test
  (testing ":pkg/brew-uninstall runs brew uninstall for each item plus autoremove"
    (let [calls (atom [])]
      (with-redefs [a/exec! (mock-exec! calls)]
        (a/install! :pkg/brew-uninstall {} {"wget" {} "curl" {}}))
      (is (some #(= ["brew" "uninstall" "wget"] %) @calls))
      (is (some #(= ["brew" "uninstall" "curl"] %) @calls))
      (is (some #(= ["brew" "autoremove"] %) @calls))))

  (testing ":pkg/brew-uninstall requires [:complete :pkg/brew]"
    (is (= [:complete :pkg/brew] (a/requires :pkg/brew-uninstall)))))

(deftest bbin-uninstall-action-test
  (testing ":pkg/bbin-uninstall runs bbin uninstall for each item"
    (let [calls (atom [])]
      (with-redefs [a/exec! (mock-exec! calls)]
        (a/install! :pkg/bbin-uninstall {} {:neil {}}))
      (is (some #(= ["bbin" "uninstall" "neil"] %) @calls))))

  (testing ":pkg/bbin-uninstall requires [:complete :pkg/bbin]"
    (is (= [:complete :pkg/bbin] (a/requires :pkg/bbin-uninstall)))))

(deftest mise-uninstall-action-test
  (testing ":pkg/mise-uninstall runs mise uninstall for each item"
    (let [calls (atom [])]
      (with-redefs [a/exec! (mock-exec! calls)]
        (a/install! :pkg/mise-uninstall {} {:python {}}))
      (is (some #(= ["mise" "uninstall" "python"] %) @calls))))

  (testing ":pkg/mise-uninstall requires [:complete :pkg/mise]"
    (is (= [:complete :pkg/mise] (a/requires :pkg/mise-uninstall)))))

(deftest mas-uninstall-action-test
  (testing ":pkg/mas-uninstall runs mas uninstall for each item"
    (let [calls (atom [])]
      (with-redefs [a/exec! (mock-exec! calls)]
        (a/install! :pkg/mas-uninstall {} {497799835 {}}))
      (is (some #(= ["mas" "uninstall" "497799835"] %) @calls))))

  (testing ":pkg/mas-uninstall requires [:complete :pkg/mas]"
    (is (= [:complete :pkg/mas] (a/requires :pkg/mas-uninstall)))))

;; =============================================================================
;; Graph ordering: uninstalls before installs
;; =============================================================================

;; =============================================================================
;; build! integration: orphans appear in plan
;; =============================================================================

(deftest build-includes-orphans-test
  (testing "build! adds uninstall actions from a/orphans to plan"
    (let [entries [{:step {:pkg/script {:bbin-bootstrap {:src "echo ok" :dep/provides #{:pkg/bbin}}}
                           :pkg/bbin {:jet {}}}
                   :source "/test"}]
          ;; Mock a/orphans to say "neil" is orphaned
          result (with-redefs [a/orphans (fn [type declared]
                                           (when (= type :pkg/bbin)
                                             {:pkg/bbin-uninstall {:neil {}}}))]
                   (p/build! entries {}))]
      ;; neil should appear as :pkg/bbin-uninstall
      (is (= {:neil {}} (get-in result [:plan :pkg/bbin-uninstall])))
      ;; uninstall should be in the order
      (is (some #{[:pkg/bbin-uninstall :neil]} (:order result)))))

  (testing "build! does not add uninstall actions when no orphans"
    (let [entries [{:step {:pkg/script {:bbin-bootstrap {:src "echo ok" :dep/provides #{:pkg/bbin}}}
                           :pkg/bbin {:jet {}}}
                   :source "/test"}]
          result (with-redefs [a/orphans (fn [_ _] nil)]
                   (p/build! entries {}))]
      (is (nil? (get-in result [:plan :pkg/bbin-uninstall]))))))

(deftest uninstall-ordering-test
  (testing "uninstall actions sort after their install counterparts ([:complete type] dep)"
    (let [plan {:pkg/brew-uninstall {:wget {}}
                :pkg/brew {:neovim {}}
                :pkg/script {:homebrew {:dep/provides #{:pkg/brew}}}}
          order (g/topological-sort plan)]
      ;; script (provides :pkg/brew), then brew (requires :pkg/brew),
      ;; then brew-uninstall (requires [:complete :pkg/brew])
      (let [positions (into {} (map-indexed (fn [i a] [a i])) order)]
        (is (> (positions [:pkg/brew-uninstall :wget])
               (positions [:pkg/brew :neovim])))))))
