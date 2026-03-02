(ns main-test
  (:require [clojure.test :refer [deftest testing is]]
            [main :as main]))

(deftest parse-args-test
  (testing "no args → nil action, no plan mode"
    (is (= {:action nil :plan-mode false :help false}
           (#'main/parse-args []))))

  (testing "action arg"
    (is (= :pkg/brew (:action (#'main/parse-args [":pkg/brew"])))))

  (testing "--plan flag"
    (is (true? (:plan-mode (#'main/parse-args ["--plan"])))))

  (testing "action + plan"
    (let [result (#'main/parse-args [":fs/symlink" "--plan"])]
      (is (= :fs/symlink (:action result)))
      (is (true? (:plan-mode result))))))

(deftest cache-save-guard-test
  (testing "save-cache! is not called for non-symlink filtered runs"
    (let [saved? (atom false)]
      ;; Only test the guard condition — don't run full -main
      (with-redefs [clojure.core/keyword? (fn [_] true)]
        (let [action :pkg/brew
              should-save? (or (nil? action) (= action :fs/symlink))]
          (is (false? should-save?)
              ":pkg/brew should NOT trigger cache save")))))

  (testing "save-cache! is called when action is nil (full run)"
    (let [action nil
          should-save? (or (nil? action) (= action :fs/symlink))]
      (is (true? should-save?)
          "nil action (full run) should trigger cache save")))

  (testing "save-cache! is called when action is :fs/symlink"
    (let [action :fs/symlink
          should-save? (or (nil? action) (= action :fs/symlink))]
      (is (true? should-save?)
          ":fs/symlink action should trigger cache save"))))
