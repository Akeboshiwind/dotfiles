(ns version-test
  (:require [clojure.test :refer [deftest testing is]]
            [version :as v]))

(deftest severity-test
  (testing "the component that moved sets the weight"
    (is (= :major (v/severity "5.6.1" "6.0.0")))
    (is (= :minor (v/severity "9.11.0" "9.12.0")))
    (is (= :patch (v/severity "7.13.1" "7.13.2"))))

  (testing "a jump of many patch releases is still a patch"
    (is (= :patch (v/severity "2.36.8" "2.36.15"))))

  (testing "0.x gets no special treatment — position is position"
    (is (= :patch (v/severity "0.0.402" "0.0.406")))
    (is (= :minor (v/severity "0.11.4" "0.12.0"))))

  (testing "schemes that are not semver fall out of the positional rule"
    (is (= :minor (v/severity "2026.7.13" "2026.8.1"))  "calendar version")
    (is (= :minor (v/severity "2024-01-01" "2024-06-01")) "date stamp")
    (is (= :patch (v/severity "8.1.2_1" "8.1.2_2"))     "brew revision")
    (is (= :patch (v/severity "1.12.5.1654" "1.12.5.1664")) "four components")
    (is (= :major (v/severity "1.4" "2.0"))             "two components"))

  (testing "a leading v is notation, not a component"
    (is (= :major (v/severity "v1.9.2" "v2.0.0")))
    (is (= :minor (v/severity "v1.9.2" "v1.10.0"))))

  (testing "a version that only grows has not moved"
    (is (= :patch (v/severity "1.2" "1.2.1")))
    (is (= :patch (v/severity "2.0.0-rc.1" "2.0.0")))
    (is (= :patch (v/severity "1.2.3" "1.2.3"))))

  (testing "any move backwards is a downgrade, at any depth"
    (is (= :downgrade (v/severity "3.0.0" "2.9.4")))
    (is (= :downgrade (v/severity "9.12.0" "9.11.0")))
    (is (= :downgrade (v/severity "7.13.2" "7.13.1"))))

  (testing "leading zeros compare as numbers, not strings"
    (is (= :minor (v/severity "1.09.0" "1.10.0"))))

  (testing "what is not a number cannot be proved safe"
    (is (= :unknown (v/severity "2026.1.1" "latest")) "a mise latest pin")
    (is (= :unknown (v/severity "a1b2c3d" "f4e5d6c")) "an opaque hash")
    (is (= :unknown (v/severity "trixie" "forky"))    "a codename"))

  (testing "a non-numeric component deep in the version stays a patch"
    (is (= :patch (v/severity "1.2.3" "1.2.beta"))))

  (testing "total — a missing version is unknown, never a crash"
    (is (= :unknown (v/severity nil "1.0.0")))
    (is (= :unknown (v/severity "1.0.0" nil)))
    (is (= :unknown (v/severity nil nil)))))

(deftest change-index-test
  (testing "indexes the first character of the part that moved"
    (is (= "12.0"  (subs "9.12.0" (v/change-index "9.11.0" "9.12.0"))))
    (is (= "15"    (subs "2.36.15" (v/change-index "2.36.8" "2.36.15"))))
    (is (= "6.0.0" (subs "6.0.0" (v/change-index "5.6.1" "6.0.0")))))

  (testing "a stripped v is still printed, and stays in the shared part"
    (is (= "2.0.0" (subs "v2.0.0" (v/change-index "v1.9.2" "v2.0.0")))))

  (testing "separators other than a dot are respected"
    (is (= "2"     (subs "8.1.2_2" (v/change-index "8.1.2_1" "8.1.2_2"))))
    (is (= "06-01" (subs "2024-06-01" (v/change-index "2024-01-01" "2024-06-01")))))

  (testing "nothing moved leaves nothing to highlight"
    (is (= "" (subs "2.0.0" (v/change-index "2.0.0-rc.1" "2.0.0"))))
    (is (= "" (subs "1.2.3" (v/change-index "1.2.3" "1.2.3")))))

  (testing "total — a missing version highlights nothing"
    (is (= 0 (v/change-index nil "1.0.0")))
    (is (= 0 (v/change-index "1.0.0" nil)))))
