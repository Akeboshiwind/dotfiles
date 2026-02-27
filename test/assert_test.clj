(ns assert-test
  (:require [clojure.test :refer [deftest testing is]]
            [clojure.string :as str]
            [execute :as e]
            [graph :as g]
            [actions :as a]))

(defn- mock-exec!
  [calls fail-pred]
  (fn [opts args]
    (swap! calls conj args)
    (if (fail-pred args)
      {:exit 1 :err "check failed"}
      {:exit 0 :err nil})))

;; =============================================================================
;; Assert action tests
;; =============================================================================

(deftest assert-pass-test
  (testing "passing assert runs and succeeds"
    (let [calls (atom [])
          plan {:assert {:ssh-key {:src "test -f ~/.ssh/id_rsa"}}}
          order (g/topological-sort plan)]
      (with-redefs [a/exec! (mock-exec! calls (constantly false))]
        (e/execute-plan {:plan plan :order order}))
      (is (= 1 (count @calls))
          "assert should execute its check"))))

(deftest assert-fail-prints-instructions-test
  (testing "failing assert prints message and instructions"
    (let [calls (atom [])
          plan {:assert {:ssh-key {:src "test -f ~/.ssh/id_rsa"
                                   :message "SSH key not found"
                                   :instructions ["Generate: ssh-keygen -t ed25519"
                                                  "Add to GitHub"]}}}
          order (g/topological-sort plan)
          output (with-out-str
                   (with-redefs [a/exec! (mock-exec! calls (constantly true))]
                     (e/execute-plan {:plan plan :order order})))]
      (is (re-find #"SSH key not found" output)
          "should print the message")
      (is (re-find #"ssh-keygen" output)
          "should print instructions")
      (is (re-find #"Add to GitHub" output)
          "should print all instruction lines"))))

(deftest assert-fail-blocks-dependent-test
  (testing "failed assert blocks actions that depend on it"
    (let [calls (atom [])
          plan {:assert {:remote-login {:src "exit 1"
                                        :message "Remote Login disabled"
                                        :instructions ["Enable in System Settings"]}}
                :pkg/script {:setup {:src "echo setup"
                                     :dep/provides #{:pkg/brew}}}
                :pkg/brew {:mosh {:dep/requires #{[:assert :remote-login]}}}}
          order (g/topological-sort plan)]
      (with-redefs [a/exec! (mock-exec! calls #(= (last %) "exit 1"))]
        (e/execute-plan {:plan plan :order order}))
      (is (some #(= (last %) "exit 1") @calls)
          "assert should run")
      (is (some #(= (last %) "echo setup") @calls)
          "independent setup should run")
      (is (not-any? #(str/includes? (str/join " " %) "mosh") @calls)
          "mosh should be skipped due to failed assert"))))

(deftest assert-pass-allows-dependent-test
  (testing "passing assert allows dependent actions to run"
    (let [calls (atom [])
          plan {:assert {:remote-login {:src "echo ok"
                                        :message "Remote Login disabled"
                                        :instructions ["Enable in System Settings"]}}
                :pkg/script {:setup {:src "echo setup"
                                     :dep/provides #{:pkg/brew}}}
                :pkg/brew {:mosh {:dep/requires #{[:assert :remote-login]}}}}
          order (g/topological-sort plan)]
      (with-redefs [a/exec! (mock-exec! calls (constantly false))]
        (e/execute-plan {:plan plan :order order}))
      (is (some #(str/includes? (str/join " " %) "mosh") @calls)
          "mosh should run when assert passes"))))

(deftest assert-requires-nil-test
  (testing "assert has no implicit dependency"
    (let [plan {:assert {:check {:src "true"}}}]
      (is (nil? (g/validate plan))
          "assert-only plan should be valid with no providers"))))

(deftest assert-validates-src-or-path-test
  (testing "assert requires :src or :path"
    (let [errors (a/validate :assert {:bad-check {:message "missing script"}})]
      (is (seq errors)
          "should produce validation error")
      (is (some #(= :bad-check (:key %)) errors)
          "error should reference the bad check"))))
