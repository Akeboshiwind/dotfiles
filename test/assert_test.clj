(ns assert-test
  (:require [clojure.test :refer [deftest testing is]]
            [clojure.string :as str]
            [execute :as e]
            [graph :as g]
            [check :as chk]
            [actions :as a]
            [outcome :as o]))

(defn- mock-exec!
  [calls fail-pred]
  (fn [opts args]
    (swap! calls conj args)
    (if (fail-pred args)
      {:exit 1 :err "check failed"}
      {:exit 0 :err nil})))

(defn- build-and-check
  "Build and check, letting assert check run for real, mocking others as unknown."
  [plan]
  (let [ag (g/build-action-graph plan)
        original-check a/check]
    (with-redefs [a/check (fn [type key opts]
                            (if (= type :assert)
                              (original-check type key opts)
                              o/unknown))]
      (chk/run-checks ag))))

;; =============================================================================
;; Assert check tests (assert is a check-only concern)
;; =============================================================================

(deftest assert-pass-test
  (testing "passing assert → satisfied in check phase"
    (let [plan {:assert {:ssh-key {:src "exit 0"}}}
          ag (build-and-check plan)
          check (get-in ag [:nodes [:assert :ssh-key] :check])]
      (is (o/satisfied? check)))))

(deftest assert-fail-prints-instructions-test
  (testing "failing assert shows instructions during execute"
    (let [plan {:assert {:ssh-key {:src "exit 1"
                                   :message "SSH key not found"
                                   :instructions ["Generate: ssh-keygen -t ed25519"
                                                  "Add to GitHub"]}}}
          ag (build-and-check plan)
          check (get-in ag [:nodes [:assert :ssh-key] :check])]
      (is (o/error? check))
      (is (= "SSH key not found" (:message check)))
      ;; Instructions must survive into the check outcome
      (is (= ["Generate: ssh-keygen -t ed25519" "Add to GitHub"]
             (:detail check))
          "instructions should be carried as :detail on the error outcome")
      ;; Instructions must be rendered during execute
      (let [output (with-out-str (e/execute-plan ag))]
        (is (str/includes? output "ssh-keygen")
            "execute output should include instruction text")))))

(deftest assert-fail-blocks-dependent-test
  (testing "failed assert blocks actions that depend on it"
    (let [calls (atom [])
          plan {:assert {:remote-login {:src "exit 1"
                                        :message "Remote Login disabled"
                                        :instructions ["Enable in System Settings"]}}
                :pkg/script {:setup {:src "echo setup"
                                     :dep/provides #{:pkg/brew}}}
                :pkg/brew {:mosh {:dep/requires #{[:assert :remote-login]}}}}
          ag (build-and-check plan)]
      (with-redefs [a/exec! (mock-exec! calls (constantly false))]
        (e/execute-plan ag))
      ;; Assert error should cancel brew:mosh but not script:setup
      (is (some #(= (last %) "echo setup") @calls)
          "independent setup should run")
      (is (not-any? #(str/includes? (str/join " " %) "mosh") @calls)
          "mosh should be skipped due to failed assert"))))

(deftest assert-pass-allows-dependent-test
  (testing "passing assert allows dependent actions to run"
    (let [calls (atom [])
          plan {:assert {:remote-login {:src "exit 0"
                                        :message "Remote Login disabled"
                                        :instructions ["Enable in System Settings"]}}
                :pkg/script {:setup {:src "echo setup"
                                     :dep/provides #{:pkg/brew}}}
                :pkg/brew {:mosh {:dep/requires #{[:assert :remote-login]}}}}
          ag (build-and-check plan)]
      (with-redefs [a/exec! (mock-exec! calls (constantly false))]
        (e/execute-plan ag))
      (is (some #(str/includes? (str/join " " %) "mosh") @calls)
          "mosh should run when assert passes"))))

(deftest assert-requires-nil-test
  (testing "assert has no implicit dependency"
    (let [plan {:assert {:check {:src "true"}}}]
      (is (nil? (g/validate plan))
          "assert-only plan should be valid with no providers"))))

(deftest assert-validates-src-or-path-test
  (testing "assert requires :src or :path — check returns error"
    (let [result (a/check :assert :bad-check {:message "missing script"})]
      (is (o/error? result)
          "should produce error outcome for missing :src/:path"))))
