(ns osx-test
  (:require [clojure.test :refer [deftest testing is]]
            [actions.osx :as osx]))

;; =============================================================================
;; map->plist-xml tests
;; =============================================================================

(deftest map->plist-xml-test
  (testing "basic string value"
    (is (= "<dict><key>name</key><string>hello</string></dict>"
           (osx/map->plist-xml {:name "hello"}))))

  (testing "integer value"
    (is (= "<dict><key>count</key><integer>42</integer></dict>"
           (osx/map->plist-xml {:count 42}))))

  (testing "boolean values"
    (is (= "<dict><key>enabled</key><true/></dict>"
           (osx/map->plist-xml {:enabled true})))
    (is (= "<dict><key>enabled</key><false/></dict>"
           (osx/map->plist-xml {:enabled false}))))

  (testing "XML special characters are escaped"
    (is (= "<dict><key>name</key><string>Tom &amp; Jerry</string></dict>"
           (osx/map->plist-xml {:name "Tom & Jerry"})))
    (is (= "<dict><key>expr</key><string>x &lt; y</string></dict>"
           (osx/map->plist-xml {:expr "x < y"})))
    (is (= "<dict><key>tag</key><string>&lt;none&gt;</string></dict>"
           (osx/map->plist-xml {:tag "<none>"}))))

  (testing "multiple special characters"
    (is (= "<dict><key>html</key><string>&lt;a href=&quot;test&quot;&gt;link&lt;/a&gt;</string></dict>"
           (osx/map->plist-xml {:html "<a href=\"test\">link</a>"})))))
