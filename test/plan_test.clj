(ns plan-test
  (:require [clojure.test :refer [deftest testing is]]
            [plan :as p]))

;; =============================================================================
;; PATH-001: Path traversal vulnerability
;; =============================================================================

(deftest path-traversal-test
  (testing "paths with ../ that escape base directory should throw"
    (let [steps [{:context {:source-dir "/Users/test/dotfiles/cfg/app"}
                  :fs/symlink {"~/.config/app" "./../../etc/passwd"}}]]
      (is (thrown-with-msg?
            clojure.lang.ExceptionInfo
            #"Path escapes base directory|Path traversal"
            (p/build steps {})))))

  (testing "paths that stay within base directory should succeed"
    (let [steps [{:context {:source-dir "/Users/test/dotfiles/cfg/app"}
                  :fs/symlink {"~/.config/app" "./config/settings.json"}}]]
      ;; This should not throw (file doesn't need to exist for path resolution)
      (is (map? (p/build steps {}))))))
