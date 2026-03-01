(ns action-graph-test
  (:require [clojure.test :refer [deftest testing is]]
            [graph :as g]
            [check :as chk]
            [actions :as a]
            [outcome :as o]
            [registry]))

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
          checked (chk/run-checks ag)]
      (is (every? #(some? (:check (val %))) (:nodes checked))))))

(deftest walk-graph-cancels-dependents-test
  (testing "error in check cancels downstream dependents"
    (let [plan {:assert {:remote-login {:src "exit 1"
                                         :message "disabled"}}
                :pkg/script {:setup {:src "echo ok"
                                      :dep/requires #{[:assert :remote-login]}}}}
          ag (g/build-action-graph plan)
          checked (chk/run-checks ag)
          assert-check (get-in checked [:nodes [:assert :remote-login] :check])
          script-check (get-in checked [:nodes [:pkg/script :setup] :check])]
      (is (o/error? assert-check))
      (is (o/cancelled? script-check)))))

(deftest walk-graph-satisfied-does-not-cancel-test
  (testing "satisfied check does not cancel dependents"
    (let [plan {:assert {:check-ok {:src "exit 0"}}
                :pkg/script {:setup {:src "echo ok"
                                      :dep/requires #{[:assert :check-ok]}}}}
          ag (g/build-action-graph plan)
          checked (chk/run-checks ag)
          assert-check (get-in checked [:nodes [:assert :check-ok] :check])
          script-check (get-in checked [:nodes [:pkg/script :setup] :check])]
      (is (o/satisfied? assert-check))
      (is (not (o/cancelled? script-check))))))
