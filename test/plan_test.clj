(ns plan-test
  (:require [clojure.test :refer [deftest testing is]]
            [plan :as p]))

;; =============================================================================
;; find-duplicate-keys tests
;; =============================================================================

(deftest find-duplicate-keys-test
  (testing "no duplicates returns empty"
    (is (empty? (p/find-duplicate-keys [])))
    (is (empty? (p/find-duplicate-keys [{:step {:pkg/brew {:neovim {}}} :source "cfg/a"}])))
    (is (empty? (p/find-duplicate-keys [{:step {:pkg/brew {:neovim {}}} :source "cfg/a"}
                                        {:step {:pkg/brew {:ripgrep {}}} :source "cfg/b"}]))))

  (testing "same key in same action type is duplicate"
    (let [errors (p/find-duplicate-keys [{:step {:pkg/brew {:neovim {}}} :source "cfg/a"}
                                         {:step {:pkg/brew {:neovim {:head true}}} :source "cfg/b"}])]
      (is (= 1 (count errors)))
      (is (= :pkg/brew (:action (first errors))))
      (is (= :neovim (:key (first errors))))
      (is (= ["cfg/a" "cfg/b"] (:sources (first errors))))
      (is (re-find #"cfg/a" (:error (first errors))))
      (is (re-find #"cfg/b" (:error (first errors))))))

  (testing "same key in different action types is not duplicate"
    (is (empty? (p/find-duplicate-keys [{:step {:pkg/brew {:node {}}} :source "cfg/a"}
                                        {:step {:pkg/mise {:node {}}} :source "cfg/b"}]))))

  (testing "multiple duplicates across action types"
    (let [errors (p/find-duplicate-keys [{:step {:pkg/brew {:neovim {} :git {}}} :source "cfg/a"}
                                         {:step {:pkg/brew {:neovim {} :ripgrep {}}} :source "cfg/b"}
                                         {:step {:pkg/mise {:node {}}} :source "cfg/c"}
                                         {:step {:pkg/mise {:node {}}} :source "cfg/d"}])]
      (is (= 2 (count errors)))
      (is (= #{[:pkg/brew :neovim] [:pkg/mise :node]}
             (set (map (juxt :action :key) errors))))))

  (testing "key in 3+ files reports all sources"
    (let [errors (p/find-duplicate-keys [{:step {:pkg/brew {:neovim {}}} :source "cfg/a"}
                                         {:step {:pkg/brew {:neovim {}}} :source "cfg/b"}
                                         {:step {:pkg/brew {:neovim {}}} :source "cfg/c"}])]
      (is (= 1 (count errors)))
      (is (= 3 (count (:sources (first errors))))))))

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
            (p/build! entries {})))))

  (testing "paths that stay within base directory should succeed"
    (let [entries [{:step {:fs/symlink {"~/.config/app" "./config/settings.json"}}
                    :source "/Users/test/dotfiles/cfg/app"}]]
      ;; This should not throw (file doesn't need to exist for path resolution)
      (is (map? (p/build! entries {}))))))

;; =============================================================================
;; PATH-002: Plain relative paths not handled
;; =============================================================================

(deftest relative-path-handling-test
  (testing "plain relative paths (no ./ prefix) should resolve"
    (let [entries [{:step {:fs/symlink {"~/.config/app" "config/settings.json"}}
                    :source "/Users/test/dotfiles/cfg/app"}]
          result (p/build! entries {})]
      (is (= "/Users/test/dotfiles/cfg/app/config/settings.json"
             (get-in result [:plan :fs/symlink "~/.config/app"])))))

  (testing "../ paths that escape base directory should throw"
    (let [entries [{:step {:fs/symlink {"~/.config/shared" "../shared/config.json"}}
                    :source "/Users/test/dotfiles/cfg/app"}]]
      (is (thrown-with-msg?
            clojure.lang.ExceptionInfo
            #"Path escapes base directory"
            (p/build! entries {})))))

  (testing "absolute paths pass through unchanged"
    (let [entries [{:step {:fs/symlink {"~/.config/app" "/etc/some/config"}}
                    :source "/Users/test/dotfiles/cfg/app"}]
          result (p/build! entries {})]
      (is (= "/etc/some/config"
             (get-in result [:plan :fs/symlink "~/.config/app"])))))

  (testing "home paths pass through unchanged"
    (let [entries [{:step {:fs/symlink {"~/.config/app" "~/some/config"}}
                    :source "/Users/test/dotfiles/cfg/app"}]
          result (p/build! entries {})]
      (is (= "~/some/config"
             (get-in result [:plan :fs/symlink "~/.config/app"]))))))

;; =============================================================================
;; calculate-unlinks: stale symlink detection
;; =============================================================================

(deftest calculate-unlinks-test
  (testing "no cache returns empty unlinks"
    (let [plan {:fs/symlink {"~/.config/a" "/src/a"}}
          result (p/calculate-unlinks {} plan)]
      (is (= {} (:unlinks result)))
      (is (= {"~/.config/a" "/src/a"} (:symlinks result)))))

  (testing "no cache symlinks returns empty unlinks"
    (let [plan {:fs/symlink {"~/.config/a" "/src/a"}}
          result (p/calculate-unlinks {:symlinks {}} plan)]
      (is (= {} (:unlinks result)))))

  (testing "cached symlink still in plan is not stale"
    (let [cache {:symlinks {"~/.config/a" "/src/a"}}
          plan {:fs/symlink {"~/.config/a" "/src/a"}}
          result (p/calculate-unlinks cache plan)]
      (is (= {} (:unlinks result)))))

  (testing "cached symlink not in plan is stale"
    (let [cache {:symlinks {"~/.config/old" "/src/old"}}
          plan {:fs/symlink {"~/.config/new" "/src/new"}}
          result (p/calculate-unlinks cache plan)]
      (is (= {"~/.config/old" "/src/old"} (:unlinks result)))
      (is (= {"~/.config/new" "/src/new"} (:symlinks result)))))

  (testing "mix of stale and current symlinks"
    (let [cache {:symlinks {"~/.config/a" "/src/a"
                            "~/.config/b" "/src/b"
                            "~/.config/c" "/src/c"}}
          plan {:fs/symlink {"~/.config/a" "/src/a"
                             "~/.config/d" "/src/d"}}
          result (p/calculate-unlinks cache plan)]
      (is (= {"~/.config/b" "/src/b"
              "~/.config/c" "/src/c"} (:unlinks result)))
      (is (= {"~/.config/a" "/src/a"
              "~/.config/d" "/src/d"} (:symlinks result)))))

  (testing "empty plan symlinks marks all cached as stale"
    (let [cache {:symlinks {"~/.config/a" "/src/a"
                            "~/.config/b" "/src/b"}}
          plan {:fs/symlink {}}
          result (p/calculate-unlinks cache plan)]
      (is (= {"~/.config/a" "/src/a"
              "~/.config/b" "/src/b"} (:unlinks result)))))

  (testing "nil plan symlinks marks all cached as stale"
    (let [cache {:symlinks {"~/.config/a" "/src/a"}}
          plan {}
          result (p/calculate-unlinks cache plan)]
      (is (= {"~/.config/a" "/src/a"} (:unlinks result))))))
