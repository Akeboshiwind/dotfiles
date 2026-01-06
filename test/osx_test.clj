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
           (osx/map->plist-xml {:html "<a href=\"test\">link</a>"}))))

  (testing "nested map"
    (is (= "<dict><key>outer</key><dict><key>inner</key><string>value</string></dict></dict>"
           (osx/map->plist-xml {:outer {:inner "value"}}))))

  (testing "array of primitives"
    (is (= "<dict><key>items</key><array><integer>1</integer><integer>2</integer><integer>3</integer></array></dict>"
           (osx/map->plist-xml {:items [1 2 3]}))))

  (testing "array of strings"
    (is (= "<dict><key>names</key><array><string>foo</string><string>bar</string></array></dict>"
           (osx/map->plist-xml {:names ["foo" "bar"]}))))

  (testing "array of maps"
    (is (= "<dict><key>users</key><array><dict><key>name</key><string>alice</string></dict><dict><key>name</key><string>bob</string></dict></array></dict>"
           (osx/map->plist-xml {:users [{:name "alice"} {:name "bob"}]}))))

  (testing "deeply nested structure"
    (is (= "<dict><key>config</key><dict><key>items</key><array><dict><key>id</key><integer>1</integer></dict></array></dict></dict>"
           (osx/map->plist-xml {:config {:items [{:id 1}]}})))))
