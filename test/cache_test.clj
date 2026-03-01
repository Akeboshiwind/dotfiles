(ns cache-test
  (:require [clojure.test :refer [deftest testing is]]
            [cache :as c]))

(deftest content-hash-test
  (testing "same content produces same hash"
    (is (= (c/content-hash "hello") (c/content-hash "hello"))))

  (testing "different content produces different hash"
    (is (not= (c/content-hash "hello") (c/content-hash "world"))))

  (testing "hash is a hex string"
    (is (re-matches #"[0-9a-f]{64}" (c/content-hash "test")))))

(deftest script-record-test
  (testing "builds record with timestamp and hash"
    (let [rec (c/script-record "echo ok")]
      (is (instance? java.util.Date (:timestamp rec)))
      (is (string? (:content-hash rec)))
      (is (= (c/content-hash "echo ok") (:content-hash rec))))))

(deftest get-put-script-test
  (testing "put and get round-trip"
    (let [rec (c/script-record "echo ok")
          cache (c/put-script {} "my-script" rec)]
      (is (= rec (c/get-script cache "my-script")))))

  (testing "get returns nil for missing script"
    (is (nil? (c/get-script {} "nonexistent")))))
