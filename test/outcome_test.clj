(ns outcome-test
  (:require [clojure.test :refer [deftest testing is]]
            [outcome :as o]))

(deftest constructors-test
  (testing "satisfied is a map with :outcome :satisfied"
    (is (= :satisfied (:outcome o/satisfied))))

  (testing "drift carries a kind"
    (is (= {:outcome :drift :kind :missing} (o/drift :missing)))
    (is (= {:outcome :drift :kind :outdated} (o/drift :outdated))))

  (testing "unknown is a map with :outcome :unknown"
    (is (= :unknown (:outcome o/unknown))))

  (testing "conflict carries a message"
    (is (= {:outcome :conflict :message "file exists"} (o/conflict "file exists"))))

  (testing "error carries a message"
    (is (= {:outcome :error :message "bad config"} (o/error "bad config"))))

  (testing "cancelled is a map with :outcome :cancelled"
    (is (= :cancelled (:outcome o/cancelled)))))

(deftest predicates-test
  (testing "satisfied?"
    (is (o/satisfied? o/satisfied))
    (is (not (o/satisfied? o/unknown))))

  (testing "drift?"
    (is (o/drift? (o/drift :missing)))
    (is (not (o/drift? o/satisfied))))

  (testing "unknown?"
    (is (o/unknown? o/unknown))
    (is (not (o/unknown? o/satisfied))))

  (testing "conflict?"
    (is (o/conflict? (o/conflict "x")))
    (is (not (o/conflict? o/satisfied))))

  (testing "error?"
    (is (o/error? (o/error "x")))
    (is (not (o/error? o/satisfied))))

  (testing "cancelled?"
    (is (o/cancelled? o/cancelled))
    (is (not (o/cancelled? o/satisfied)))))

(deftest actionable-test
  (testing "drift and unknown are actionable"
    (is (o/actionable? (o/drift :missing)))
    (is (o/actionable? o/unknown)))

  (testing "satisfied, error, conflict, cancelled are not actionable"
    (is (not (o/actionable? o/satisfied)))
    (is (not (o/actionable? (o/error "x"))))
    (is (not (o/actionable? (o/conflict "x"))))
    (is (not (o/actionable? o/cancelled)))))

(deftest blocking-test
  (testing "error, conflict, cancelled are blocking"
    (is (o/blocking? (o/error "x")))
    (is (o/blocking? (o/conflict "x")))
    (is (o/blocking? o/cancelled)))

  (testing "satisfied, drift, unknown are not blocking"
    (is (not (o/blocking? o/satisfied)))
    (is (not (o/blocking? (o/drift :missing))))
    (is (not (o/blocking? o/unknown)))))

(deftest from-legacy-state-test
  (testing "maps legacy status keywords to CheckOutcome"
    (is (o/satisfied? (o/from-legacy-state :installed)))
    (is (= (o/drift :missing) (o/from-legacy-state :missing)))
    (is (= (o/drift :outdated) (o/from-legacy-state :outdated)))
    (is (= (o/drift :wrong) (o/from-legacy-state :wrong)))
    (is (= (o/drift :orphan) (o/from-legacy-state :orphan)))
    (is (o/unknown? (o/from-legacy-state :unknown)))))
