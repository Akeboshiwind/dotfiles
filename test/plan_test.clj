(ns plan-test
  (:require [clojure.test :refer [deftest testing is]]
            [plan :as p]))

;; =============================================================================
;; PATH-001: Path traversal vulnerability
;; =============================================================================

(deftest path-traversal-test
  (testing "paths with ../ that escape base directory should throw"
    (let [entries [{:step {:fs/symlink {"~/.config/app" "./../../etc/passwd"}}
                    :source "/Users/test/dotfiles/cfg/app"}]]
      (is (thrown-with-msg?
            clojure.lang.ExceptionInfo
            #"Path escapes base directory|Path traversal"
            (p/build entries {})))))

  (testing "paths that stay within base directory should succeed"
    (let [entries [{:step {:fs/symlink {"~/.config/app" "./config/settings.json"}}
                    :source "/Users/test/dotfiles/cfg/app"}]]
      ;; This should not throw (file doesn't need to exist for path resolution)
      (is (map? (p/build entries {}))))))
