(ns execute-test
  (:require [clojure.test :refer [deftest testing is]]
            [clojure.string :as str]
            [execute :as e]
            [graph :as g]
            [actions :as a]))

(defn- mock-exec!
  "Returns a mock exec! fn that tracks calls in `calls` atom.
   `fail-pred` takes the command args vector, returns true to simulate failure."
  [calls fail-pred]
  (fn [opts args]
    (swap! calls conj args)
    (if (fail-pred args)
      {:exit 1 :err "forced failure"}
      {:exit 0 :err nil})))

;; =============================================================================
;; Failure propagation tests
;; =============================================================================

(deftest skip-dependent-within-same-type-test
  (testing "within same type, failed item causes its dependent to skip"
    (let [calls (atom [])
          plan {:pkg/script {:setup {:src "exit 1"
                                     :dep/provides #{:test/cap}}
                             :dependent {:src "echo dep"
                                         :dep/requires #{[:pkg/script :setup]}}
                             :independent {:src "echo ind"}}}
          order (g/topological-sort plan)]
      (with-redefs [a/exec! (mock-exec! calls #(= (last %) "exit 1"))]
        (e/execute-plan {:plan plan :order order}))
      (is (some #(= (last %) "exit 1") @calls)
          "setup should run")
      (is (some #(= (last %) "echo ind") @calls)
          "independent should run")
      (is (not-any? #(= (last %) "echo dep") @calls)
          "dependent should be skipped"))))

(deftest skip-dependent-across-types-test
  (testing "failure in provider skips all dependents of that capability"
    (let [calls (atom [])
          plan {:pkg/script {:bootstrap {:src "exit 1"
                                         :dep/provides #{:pkg/brew}}}
                :pkg/brew {:neovim {} :ripgrep {}}}
          order (g/topological-sort plan)]
      (with-redefs [a/exec! (mock-exec! calls #(= (last %) "exit 1"))]
        (e/execute-plan {:plan plan :order order}))
      (is (= 1 (count @calls))
          "only bootstrap should have been attempted")
      (is (not-any? #(str/includes? (str/join " " %) "neovim") @calls)
          "neovim should be skipped")
      (is (not-any? #(str/includes? (str/join " " %) "ripgrep") @calls)
          "ripgrep should be skipped"))))

(deftest transitive-skip-test
  (testing "failure propagates transitively: A fails → B skipped → C skipped"
    (let [calls (atom [])
          plan {:pkg/script {:bootstrap {:src "exit 1"
                                         :dep/provides #{:pkg/brew}}}
                :pkg/brew {:mise {:dep/provides #{:pkg/mise}}}
                :pkg/mise {:node {:version "20"}}}
          order (g/topological-sort plan)]
      (with-redefs [a/exec! (mock-exec! calls #(= (last %) "exit 1"))]
        (e/execute-plan {:plan plan :order order}))
      (is (= 1 (count @calls))
          "only bootstrap should have been attempted"))))

(deftest skip-renders-message-test
  (testing "skipped actions appear in output and are not executed"
    (let [calls (atom [])
          plan {:pkg/script {:bootstrap {:src "exit 1"
                                         :dep/provides #{:pkg/brew}}}
                :pkg/brew {:neovim {}}}
          order (g/topological-sort plan)
          output (with-out-str
                   (with-redefs [a/exec! (mock-exec! calls #(= (last %) "exit 1"))]
                     (e/execute-plan {:plan plan :order order})))]
      (is (re-find #"(?i)neovim.*skip" output)
          "skipped item should appear in output with skip indicator")
      (is (not-any? #(str/includes? (str/join " " %) "neovim") @calls)
          "neovim should not have been executed"))))

(deftest no-failure-runs-all-test
  (testing "when nothing fails, all actions execute"
    (let [calls (atom [])
          plan {:pkg/script {:setup {:src "echo setup"
                                     :dep/provides #{:pkg/brew}}}
                :pkg/brew {:neovim {}}}
          order (g/topological-sort plan)]
      (with-redefs [a/exec! (mock-exec! calls (constantly false))]
        (e/execute-plan {:plan plan :order order}))
      (is (= 2 (count @calls))
          "both actions should run"))))

(deftest mise-failure-propagates-test
  (testing "failed mise install blocks downstream dependents"
    (let [calls (atom [])
          plan {:pkg/script {:bootstrap {:src "echo ok"
                                         :dep/provides #{:pkg/brew}}}
                :pkg/brew {:mise {:dep/provides #{:pkg/mise}}}
                :pkg/mise {:node {:version "20"
                                  :dep/provides #{:pkg/npm}}}
                :pkg/npm {:neovim {}}}
          order (g/topological-sort plan)]
      ;; Make mise install fail (command contains "node@20")
      (with-redefs [a/exec! (mock-exec! calls #(str/includes? (str/join " " %) "node@20"))]
        (e/execute-plan {:plan plan :order order}))
      (is (some #(str/includes? (str/join " " %) "node@20") @calls)
          "mise install node@20 should have been attempted")
      (is (not-any? #(str/includes? (str/join " " %) "npm") @calls)
          "npm neovim should be skipped because mise:node failed"))))

(deftest osx-defaults-failure-propagates-test
  (testing "failed osx/defaults blocks downstream dependents"
    (let [calls (atom [])
          plan {:osx/defaults {:dock {:domain "com.apple.dock"
                                      :key "autohide"
                                      :value true
                                      :dep/provides #{:test/dock-configured}}}
                :pkg/script {:post-dock {:src "echo restart-dock"
                                         :dep/requires #{[:osx/defaults :dock]}}}}
          order (g/topological-sort plan)]
      ;; Make defaults write fail
      (with-redefs [a/exec! (mock-exec! calls #(str/includes? (str/join " " %) "defaults"))]
        (e/execute-plan {:plan plan :order order}))
      (is (some #(str/includes? (str/join " " %) "defaults") @calls)
          "defaults write should have been attempted")
      (is (not-any? #(str/includes? (str/join " " %) "restart-dock") @calls)
          "post-dock script should be skipped because osx/defaults:dock failed"))))

(deftest independent-branches-unaffected-test
  (testing "failure in one branch doesn't affect independent branch"
    (let [calls (atom [])
          plan {:pkg/script {:fails {:src "exit 1"}
                             :succeeds {:src "echo ok"}}
                :osx/defaults {:setting {:domain "com.example"
                                         :key "foo"
                                         :value true
                                         :dep/requires #{[:pkg/script :fails]}}}}
          order (g/topological-sort plan)]
      (with-redefs [a/exec! (mock-exec! calls #(= (last %) "exit 1"))]
        (e/execute-plan {:plan plan :order order}))
      (is (some #(= (last %) "echo ok") @calls)
          "succeeds script should run")
      (is (some #(= (last %) "exit 1") @calls)
          "fails script should run (and fail)")
      ;; osx/defaults depends on the failing script — should be skipped
      (is (not-any? #(str/includes? (str/join " " %) "defaults") @calls)
          "osx/defaults depending on failed script should be skipped"))))
