(ns execute-test
  (:require [clojure.test :refer [deftest testing is]]
            [clojure.string :as str]
            [execute :as e]
            [graph :as g]
            [check :as chk]
            [actions :as a]
            [outcome :as o]))

(defn- mock-exec!
  "Returns a mock exec! fn that tracks calls in `calls` atom.
   `fail-pred` takes the command args vector, returns true to simulate failure."
  [calls fail-pred]
  (fn [opts args]
    (swap! calls conj args)
    (if (fail-pred args)
      {:exit 1 :err "forced failure"}
      {:exit 0 :err nil})))

(defn- build-and-check
  "Build ActionGraph and run checks. Returns checked graph.
   Overrides a/check to return unknown for all types so execute tests
   focus purely on execution logic, not check behavior."
  [plan]
  (let [ag (g/build-action-graph plan)]
    (with-redefs [a/check (fn [_ _ _] o/unknown)]
      (chk/run-checks ag))))

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
          ag (build-and-check plan)]
      (with-redefs [a/exec! (mock-exec! calls #(= (last %) "exit 1"))]
        (e/execute-plan ag))
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
          ag (build-and-check plan)
          result (with-redefs [a/exec! (mock-exec! calls #(= (last %) "exit 1"))]
                   (e/execute-plan ag))]
      (is (= 1 (count @calls))
          "only bootstrap should have been attempted")
      ;; Verify graph state
      (is (= :skip (:status (get-in result [:nodes [:pkg/brew :neovim] :result])))
          "neovim node should have skip result")
      (is (o/cancelled? (get-in result [:nodes [:pkg/brew :neovim] :check]))
          "neovim node should be cancelled"))))

(deftest transitive-skip-test
  (testing "failure propagates transitively: A fails → B skipped → C skipped"
    (let [calls (atom [])
          plan {:pkg/script {:bootstrap {:src "exit 1"
                                         :dep/provides #{:pkg/brew}}}
                :pkg/brew {:mise {:dep/provides #{:pkg/mise}}}
                :pkg/mise {:node {:version "20"}}}
          ag (build-and-check plan)]
      (with-redefs [a/exec! (mock-exec! calls #(= (last %) "exit 1"))]
        (e/execute-plan ag))
      (is (= 1 (count @calls))
          "only bootstrap should have been attempted"))))

(deftest no-failure-runs-all-test
  (testing "when nothing fails, all actions execute"
    (let [calls (atom [])
          plan {:pkg/script {:setup {:src "echo setup"
                                     :dep/provides #{:pkg/brew}}}
                :pkg/brew {:neovim {}}}
          ag (build-and-check plan)
          result (with-redefs [a/exec! (mock-exec! calls (constantly false))]
                   (e/execute-plan ag))]
      (is (= 2 (count @calls))
          "both actions should run")
      ;; Verify graph state — both nodes should have results
      (is (some? (get-in result [:nodes [:pkg/script :setup] :result]))
          "setup node should have a result")
      (is (some? (get-in result [:nodes [:pkg/brew :neovim] :result]))
          "neovim node should have a result"))))

(deftest mise-failure-propagates-test
  (testing "failed mise install blocks downstream dependents"
    (let [calls (atom [])
          plan {:pkg/script {:bootstrap {:src "echo ok"
                                         :dep/provides #{:pkg/brew}}}
                :pkg/brew {:mise {:dep/provides #{:pkg/mise}}}
                :pkg/mise {:node {:version "20"
                                  :dep/provides #{:pkg/npm}}}
                :pkg/npm {:neovim {}}}
          ag (build-and-check plan)]
      ;; Make mise install fail (command contains "node@20")
      (with-redefs [a/exec! (mock-exec! calls #(str/includes? (str/join " " %) "node@20"))]
        (e/execute-plan ag))
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
          ag (build-and-check plan)]
      ;; Make defaults write fail
      (with-redefs [a/exec! (mock-exec! calls #(str/includes? (str/join " " %) "defaults"))]
        (e/execute-plan ag))
      (is (some #(str/includes? (str/join " " %) "defaults") @calls)
          "defaults write should have been attempted")
      (is (not-any? #(str/includes? (str/join " " %) "restart-dock") @calls)
          "post-dock script should be skipped because osx/defaults:dock failed"))))

(deftest batch-install-per-type-test
  (testing "install! is called once per type with all actionable items batched"
    (let [install-calls (atom [])
          plan {:pkg/script {:bootstrap {:src "echo ok"
                                          :dep/provides #{:pkg/brew}}}
                :pkg/brew {:neovim {} :ripgrep {} :wget {}}}
          ag (build-and-check plan)]
      (with-redefs [a/exec! (mock-exec! (atom []) (constantly false))
                    a/do-install! (fn [type opts items]
                                    (swap! install-calls conj {:type type :items items})
                                    (mapv (fn [[k _]]
                                            {:action [type k]
                                             :label (name k)
                                             :status :ok})
                                          items))]
        (e/execute-plan ag))
      ;; Script gets one call, brew gets ONE call with all 3 items
      (let [brew-calls (filter #(= :pkg/brew (:type %)) @install-calls)]
        (is (= 1 (count brew-calls))
            "brew should be called exactly once as a batch")
        (is (= 3 (count (:items (first brew-calls))))
            "the single brew call should contain all 3 items")))))

(deftest batch-split-by-interleaved-dependency-test
  (testing "same type split into two batches when a different type appears between them"
    ;; Order should be: [brew:a, brew:b] then [script:mid] then [brew:c, brew:d]
    ;; because c and d depend on script:mid. This should produce 2 brew batches.
    (let [install-calls (atom [])
          plan {:pkg/script {:bootstrap {:src "echo ok"
                                          :dep/provides #{:pkg/brew}}
                             :mid {:src "echo mid"
                                    :dep/provides #{:test/mid}}}
                :pkg/brew {:a {} :b {}
                           :c {:dep/requires #{:test/mid}}
                           :d {:dep/requires #{:test/mid}}}}
          ag (build-and-check plan)]
      (with-redefs [a/exec! (mock-exec! (atom []) (constantly false))
                    a/do-install! (fn [type opts items]
                                    (swap! install-calls conj {:type type :items items})
                                    (mapv (fn [[k _]]
                                            {:action [type k]
                                             :label (name k)
                                             :status :ok})
                                          items))]
        (e/execute-plan ag))
      ;; Order: [script:bootstrap, brew:a+b, script:mid, brew:c+d]
      (let [brew-calls (filter #(= :pkg/brew (:type %)) @install-calls)
            script-calls (filter #(= :pkg/script (:type %)) @install-calls)]
        (is (= 2 (count brew-calls))
            "brew should be called twice — split by interleaved script")
        (is (= 2 (count (:items (first brew-calls))))
            "first brew batch has a and b")
        (is (= 2 (count (:items (second brew-calls))))
            "second brew batch has c and d")
        (is (= 2 (count script-calls))
            "script called twice (bootstrap + mid)")))))

(deftest independent-branches-unaffected-test
  (testing "failure in one branch doesn't affect independent branch"
    (let [calls (atom [])
          plan {:pkg/script {:fails {:src "exit 1"}
                             :succeeds {:src "echo ok"}}
                :osx/defaults {:setting {:domain "com.example"
                                         :key "foo"
                                         :value true
                                         :dep/requires #{[:pkg/script :fails]}}}}
          ag (build-and-check plan)]
      (with-redefs [a/exec! (mock-exec! calls #(= (last %) "exit 1"))]
        (e/execute-plan ag))
      (is (some #(= (last %) "echo ok") @calls)
          "succeeds script should run")
      (is (some #(= (last %) "exit 1") @calls)
          "fails script should run (and fail)")
      ;; osx/defaults depends on the failing script — should be skipped
      (is (not-any? #(str/includes? (str/join " " %) "defaults") @calls)
          "osx/defaults depending on failed script should be skipped"))))
