(ns action-graph-test
  (:require [clojure.test :refer [deftest testing is]]
            [graph :as g]
            [actions :as a]
            [outcome :as o]
            [registry]
            [support]))

(deftest build-action-graph-structure-test
  (testing "builds nodes map with correct structure"
    (let [plan {:pkg/script {:setup {:src "echo ok"
                                      :dep/provides #{:pkg/brew}}}
                :pkg/brew {:neovim {}}}
          ag (g/build-action-graph plan)]
      (is (map? (:nodes ag)))
      (is (vector? (:order ag)))
      (is (= 2 (count (:nodes ag))))
      (is (contains? (:nodes ag) [:pkg/script :setup]))
      (is (contains? (:nodes ag) [:pkg/brew :neovim]))
      (let [node (get-in ag [:nodes [:pkg/brew :neovim]])]
        (is (= [:pkg/brew :neovim] (:ref node)))
        (is (= {} (:opts node)))
        (is (nil? (:check node)))))))

(deftest build-action-graph-order-test
  (testing "order respects dependencies"
    (let [plan {:pkg/script {:setup {:src "echo ok"
                                      :dep/provides #{:pkg/brew}}}
                :pkg/brew {:neovim {}}}
          ag (g/build-action-graph plan)
          order (:order ag)]
      (is (< (.indexOf order [:pkg/script :setup])
              (.indexOf order [:pkg/brew :neovim]))))))

(deftest build-action-graph-validates-test
  (testing "throws on invalid graph"
    (is (thrown? clojure.lang.ExceptionInfo
          (g/build-action-graph
            {:pkg/brew {:neovim {:dep/requires #{[:pkg/script :missing]}}}})))))

(deftest walk-graph-check-phase-test
  (testing "check phase populates :check on each node"
    (let [plan {:fs/symlink {}}
          ;; Simple plan with no real actions — use default unknown
          ag (g/build-action-graph {:pkg/script {:a {:src "echo"}}})
          checked (support/run-checks-live ag)]
      (is (every? #(some? (:check (val %))) (:nodes checked))))))

(deftest walk-graph-cancels-dependents-test
  (testing "error in check cancels downstream dependents"
    (let [plan {:assert {:remote-login {:src "exit 1"
                                         :message "disabled"}}
                :pkg/script {:setup {:src "echo ok"
                                      :dep/requires #{[:assert :remote-login]}}}}
          ag (g/build-action-graph plan)
          checked (support/run-checks-live ag)
          assert-check (get-in checked [:nodes [:assert :remote-login] :check])
          script-check (get-in checked [:nodes [:pkg/script :setup] :check])]
      (is (o/error? assert-check))
      (is (o/cancelled? script-check)))))

(deftest walk-graph-complete-cap-cancels-dependents-test
  (testing "error in a brew action cancels brew's exclusive node (via [:complete :pkg/brew])"
    (let [plan {:pkg/script {:bootstrap {:src "echo ok"
                                          :dep/provides #{:pkg/brew}}}
                :pkg/brew {:neovim {}}
                :syn/exclusive {:pkg/brew {:dep/requires #{[:complete :pkg/brew]}}}}
          ag (g/build-action-graph plan)]
      (with-redefs [a/check (fn [type key _ _]
                              (cond
                                (= [type key] [:pkg/brew :neovim]) (o/error "install failed")
                                (= type :syn/exclusive) o/unknown
                                :else o/satisfied))]
        (let [checked (support/run-checks-live ag)
              brew-check (get-in checked [:nodes [:pkg/brew :neovim] :check])
              exclusive-check (get-in checked [:nodes [:syn/exclusive :pkg/brew] :check])]
          (is (o/error? brew-check))
          (is (o/cancelled? exclusive-check)
              "removal should be cancelled when a brew action errors"))))))

(deftest walk-graph-exception-becomes-error-test
  (testing "exception thrown in check is caught and becomes error outcome"
    (let [plan {:assert {:check-ok {:src "exit 0"}}
                :pkg/script {:setup {:src "echo ok"
                                      :dep/requires #{[:assert :check-ok]}}}}
          ag (g/build-action-graph plan)]
      ;; Mock: assert throws an exception instead of returning an outcome
      (with-redefs [a/check (fn [type key _ _]
                              (if (= type :assert)
                                (throw (Exception. "boom"))
                                o/unknown))]
        (let [checked (support/run-checks-live ag)
              assert-check (get-in checked [:nodes [:assert :check-ok] :check])
              script-check (get-in checked [:nodes [:pkg/script :setup] :check])]
          (is (o/error? assert-check)
              "thrown exception should become error outcome")
          (is (= "boom" (:message assert-check)))
          (is (o/cancelled? script-check)
              "dependent should be cancelled when upstream throws"))))))

(deftest walk-graph-conflict-cancels-dependents-test
  (testing "conflict outcome cancels downstream dependents"
    (let [plan {:pkg/script {:setup {:src "echo ok"
                                      :dep/provides #{:pkg/brew}}}
                :pkg/brew {:neovim {}}}
          ag (g/build-action-graph plan)]
      (with-redefs [a/check (fn [type key _ _]
                              (if (= type :pkg/script)
                                (o/conflict "file exists")
                                o/unknown))]
        (let [checked (support/run-checks-live ag)
              script-check (get-in checked [:nodes [:pkg/script :setup] :check])
              brew-check (get-in checked [:nodes [:pkg/brew :neovim] :check])]
          (is (o/conflict? script-check))
          (is (o/cancelled? brew-check)))))))

(deftest walk-graph-multi-hop-cancellation-test
  (testing "cancellation propagates transitively: A→B→C"
    (let [plan {:assert {:check {:src "exit 1" :message "nope"}}
                :pkg/script {:setup {:src "echo ok"
                                      :dep/requires #{[:assert :check]}
                                      :dep/provides #{:pkg/brew}}}
                :pkg/brew {:neovim {}}}
          ag (g/build-action-graph plan)]
      (let [checked (support/run-checks-live ag)
            assert-check (get-in checked [:nodes [:assert :check] :check])
            script-check (get-in checked [:nodes [:pkg/script :setup] :check])
            brew-check (get-in checked [:nodes [:pkg/brew :neovim] :check])]
        (is (o/error? assert-check))
        (is (o/cancelled? script-check))
        (is (o/cancelled? brew-check)
            "three-hop: assert error → script cancelled → brew cancelled")))))

(deftest walk-graph-satisfied-does-not-cancel-test
  (testing "satisfied check does not cancel dependents"
    (let [plan {:assert {:check-ok {:src "exit 0"}}
                :pkg/script {:setup {:src "echo ok"
                                      :dep/requires #{[:assert :check-ok]}}}}
          ag (g/build-action-graph plan)
          checked (support/run-checks-live ag)
          assert-check (get-in checked [:nodes [:assert :check-ok] :check])
          script-check (get-in checked [:nodes [:pkg/script :setup] :check])]
      (is (o/satisfied? assert-check))
      (is (not (o/cancelled? script-check))))))
