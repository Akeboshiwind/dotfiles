(ns manifest-test
  (:require [clojure.test :refer [deftest testing is]]
            [manifest :as m]))

;; =============================================================================
;; secret-reader' tests
;; =============================================================================

(deftest secret-reader-test
  (testing "returns value when key exists"
    (is (= "my-secret" (m/secret-reader' {:api-key "my-secret"} :api-key)))
    (is (= 123 (m/secret-reader' {:num 123} :num))))

  (testing "returns nil when value is nil"
    (is (nil? (m/secret-reader' {:api-key nil} :api-key))))

  (testing "returns empty string when value is empty"
    (is (= "" (m/secret-reader' {:api-key ""} :api-key))))

  (testing "returns :secret/disabled as-is"
    (is (= :secret/disabled (m/secret-reader' {:api-key :secret/disabled} :api-key))))

  (testing "throws when key not found"
    (is (thrown-with-msg? clojure.lang.ExceptionInfo #"Secret not found"
          (m/secret-reader' {:other "value"} :api-key)))
    (is (thrown-with-msg? clojure.lang.ExceptionInfo #"Secret not found"
          (m/secret-reader' {} :api-key)))))

;; =============================================================================
;; entry->path tests
;; =============================================================================

(deftest entry->path-test
  (testing "string entries pass through"
    (is (= "foo.edn" (m/entry->path "foo.edn")))
    (is (= "cfg/custom/path.edn" (m/entry->path "cfg/custom/path.edn"))))

  (testing "keyword entries expand to cfg path"
    (is (= "cfg/git/base.edn" (m/entry->path :git)))
    (is (= "cfg/neovim/base.edn" (m/entry->path :neovim)))
    (is (= "cfg/some-app/base.edn" (m/entry->path :some-app))))

  (testing "maps return nil"
    (is (nil? (m/entry->path {})))
    (is (nil? (m/entry->path {:pkg/brew {:git {}}}))))

  (testing "other types return nil"
    (is (nil? (m/entry->path 123)))
    (is (nil? (m/entry->path [:vector])))))

;; =============================================================================
;; resolve-entry' tests
;; =============================================================================

(deftest resolve-entry-test
  (testing "string entries call read-fn with string"
    (let [calls (atom [])]
      (m/resolve-entry' #(do (swap! calls conj %) {:read %}) "custom.edn")
      (is (= ["custom.edn"] @calls))))

  (testing "keyword entries call read-fn with expanded path"
    (let [calls (atom [])]
      (m/resolve-entry' #(do (swap! calls conj %) {:read %}) :git)
      (is (= ["cfg/git/base.edn"] @calls))))

  (testing "map entries return as-is without calling read-fn"
    (let [calls (atom [])
          result (m/resolve-entry' #(do (swap! calls conj %) {:read %})
                                   {:pkg/brew {:neovim {}}})]
      (is (= {:pkg/brew {:neovim {}}} result))
      (is (empty? @calls))))

  (testing "invalid entries throw"
    (is (thrown-with-msg? clojure.lang.ExceptionInfo #"Invalid entry"
          (m/resolve-entry' identity 123)))
    (is (thrown-with-msg? clojure.lang.ExceptionInfo #"Invalid entry"
          (m/resolve-entry' identity [:vector])))))

;; =============================================================================
;; validate-secrets' tests
;; =============================================================================

(deftest validate-secrets-test
  (testing "valid secrets return empty"
    (is (empty? (m/validate-secrets' {:api-key "valid-secret"})))
    (is (empty? (m/validate-secrets' {:a "foo" :b "bar"})))
    (is (empty? (m/validate-secrets' {}))))

  (testing ":secret/disabled is allowed"
    (is (empty? (m/validate-secrets' {:api-key :secret/disabled})))
    (is (empty? (m/validate-secrets' {:a "valid" :b :secret/disabled}))))

  (testing "nil values return error"
    (let [errors (m/validate-secrets' {:api-key nil})]
      (is (= 1 (count errors)))
      (is (= :api-key (:key (first errors))))
      (is (= :secret (:action (first errors))))))

  (testing "empty string values return error"
    (let [errors (m/validate-secrets' {:api-key ""})]
      (is (= 1 (count errors)))
      (is (= :api-key (:key (first errors))))))

  (testing "multiple invalid secrets return multiple errors"
    (let [errors (m/validate-secrets' {:a nil :b "" :c "valid" :d :secret/disabled})]
      (is (= 2 (count errors)))
      (is (= #{:a :b} (set (map :key errors)))))))
