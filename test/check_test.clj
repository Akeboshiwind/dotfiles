(ns check-test
  (:require [clojure.test :refer [deftest testing is use-fixtures]]
            [babashka.fs :as fs]
            [actions :as a]
            [outcome :as o]
            [registry]))

;; =============================================================================
;; Temp directory fixture
;; =============================================================================

(def ^:dynamic *tmp* nil)

(defn tmp-fixture [f]
  (let [dir (str (fs/create-temp-dir {:prefix "check-test-"}))]
    (binding [*tmp* dir]
      (try (f)
           (finally (fs/delete-tree dir))))))

(use-fixtures :each tmp-fixture)

;; =============================================================================
;; :fs/symlink check
;; =============================================================================

(deftest symlink-check-satisfied-test
  (testing "correct symlink → satisfied"
    (let [source (str *tmp* "/source.txt")
          target (str *tmp* "/link.txt")]
      (spit source "hello")
      (fs/create-sym-link target source)
      (is (o/satisfied? (a/check :fs/symlink target source))))))

(deftest symlink-check-missing-test
  (testing "target doesn't exist → drift(:missing)"
    (let [source (str *tmp* "/source.txt")
          target (str *tmp* "/nolink.txt")]
      (spit source "hello")
      (let [result (a/check :fs/symlink target source)]
        (is (o/drift? result))
        (is (= :missing (:kind result)))))))

(deftest symlink-check-wrong-symlink-test
  (testing "symlink pointing to wrong target → drift(:wrong)"
    (let [source (str *tmp* "/source.txt")
          other (str *tmp* "/other.txt")
          target (str *tmp* "/link.txt")]
      (spit source "hello")
      (spit other "world")
      (fs/create-sym-link target other)
      (let [result (a/check :fs/symlink target source)]
        (is (o/drift? result))
        (is (= :wrong (:kind result)))))))

(deftest symlink-check-regular-file-test
  (testing "regular file at target → conflict"
    (let [source (str *tmp* "/source.txt")
          target (str *tmp* "/file.txt")]
      (spit source "hello")
      (spit target "existing")
      (is (o/conflict? (a/check :fs/symlink target source))))))

;; =============================================================================
;; :fs/unlink check
;; =============================================================================

(deftest unlink-check-gone-test
  (testing "target doesn't exist → satisfied"
    (let [target (str *tmp* "/gone.txt")]
      (is (o/satisfied? (a/check :fs/unlink target "/some/source"))))))

(deftest unlink-check-stale-symlink-test
  (testing "valid stale symlink → drift(:orphan)"
    (let [source (str *tmp* "/source.txt")
          target (str *tmp* "/stale.txt")]
      (spit source "hello")
      (fs/create-sym-link target source)
      (let [result (a/check :fs/unlink target source)]
        (is (o/drift? result))
        (is (= :orphan (:kind result)))))))

(deftest unlink-check-not-symlink-test
  (testing "regular file at target → conflict"
    (let [target (str *tmp* "/file.txt")]
      (spit target "hello")
      (is (o/conflict? (a/check :fs/unlink target "/some/source"))))))

(deftest unlink-check-wrong-target-test
  (testing "symlink points elsewhere → conflict"
    (let [other (str *tmp* "/other.txt")
          target (str *tmp* "/link.txt")]
      (spit other "hello")
      (fs/create-sym-link target other)
      (is (o/conflict? (a/check :fs/unlink target "/expected/source"))))))
