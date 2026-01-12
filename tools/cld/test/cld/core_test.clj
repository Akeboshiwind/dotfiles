(ns cld.core-test
  (:require [clojure.test :refer [deftest testing is]]
            [cld.core :as core]))

;; =============================================================================
;; Name Handling Tests
;; =============================================================================

(deftest sanitize-name-test
  (testing "replaces underscores with dashes"
    (is (= "my-project" (core/sanitize-name "my_project"))))

  (testing "replaces slashes with dashes"
    (is (= "foo-bar" (core/sanitize-name "foo/bar"))))

  (testing "preserves already valid names"
    (is (= "valid-name" (core/sanitize-name "valid-name"))))

  (testing "collapses multiple dashes"
    (is (= "a-b" (core/sanitize-name "a__b"))))

  (testing "removes leading/trailing dashes"
    (is (= "name" (core/sanitize-name "-name-")))))

(deftest make-session-name-test
  (testing "basic project name"
    (is (= "claude-myapp" (core/make-session-name {:project "myapp"}))))

  (testing "with suffix"
    (is (= "claude-myapp-testing" (core/make-session-name {:project "myapp" :suffix "testing"}))))

  (testing "sanitizes project name"
    (is (= "claude-my-app" (core/make-session-name {:project "my_app"}))))

  (testing "sanitizes suffix"
    (is (= "claude-myapp-feature-auth" (core/make-session-name {:project "myapp" :suffix "feature/auth"})))))

(deftest parse-session-name-test
  (testing "simple session name"
    (is (= {:project "myapp" :suffix nil}
           (core/parse-session-name "claude-myapp"))))

  (testing "session with suffix"
    (is (= {:project "myapp" :suffix "testing"}
           (core/parse-session-name "claude-myapp-testing"))))

  (testing "non-claude session returns nil"
    (is (nil? (core/parse-session-name "not-claude-session")))))

(deftest ensure-prefix-test
  (testing "adds prefix when missing"
    (is (= "claude-myapp" (core/ensure-prefix "myapp"))))

  (testing "keeps prefix when present"
    (is (= "claude-myapp" (core/ensure-prefix "claude-myapp")))))

;; =============================================================================
;; Project Resolution Tests
;; =============================================================================

(deftest resolve-project-input-test
  (testing "nil input returns cwd type"
    (is (= {:type :cwd}
           (core/resolve-project-input nil))))

  (testing "github url extracts repo name"
    (is (= {:type :github
            :url "https://github.com/user/repo"
            :repo "repo"}
           (core/resolve-project-input "https://github.com/user/repo"))))

  (testing "github url strips .git suffix"
    (is (= {:type :github
            :url "https://github.com/user/repo.git"
            :repo "repo"}
           (core/resolve-project-input "https://github.com/user/repo.git"))))

  (testing "absolute path"
    (is (= {:type :absolute-path :path "/home/user/project"}
           (core/resolve-project-input "/home/user/project"))))

  (testing "relative path with ./"
    (is (= {:type :relative-path :path "./myproject"}
           (core/resolve-project-input "./myproject"))))

  (testing "relative path with ../"
    (is (= {:type :relative-path :path "../other"}
           (core/resolve-project-input "../other"))))

  (testing "plain name"
    (is (= {:type :project-name :name "myproject"}
           (core/resolve-project-input "myproject")))))

(deftest build-project-plan-test
  (let [base-context {:cwd "/home/user/current"
                      :projects-dir "/home/user/projects"
                      :path-exists? (constantly false)}]

    (testing "cwd uses current directory"
      (is (= {:name "current" :path "/home/user/current" :action :use-existing}
             (core/build-project-plan {:type :cwd} base-context))))

    (testing "github with non-existent path -> clone"
      (is (= {:name "repo"
              :path "/home/user/projects/repo"
              :action :clone-repo
              :clone-url "https://github.com/user/repo"}
             (core/build-project-plan
              {:type :github :url "https://github.com/user/repo" :repo "repo"}
              base-context))))

    (testing "github with existing path -> use existing"
      (is (= {:name "repo"
              :path "/home/user/projects/repo"
              :action :use-existing}
             (core/build-project-plan
              {:type :github :url "https://github.com/user/repo" :repo "repo"}
              (assoc base-context :path-exists? (constantly true))))))

    (testing "project name with existing dir -> use existing"
      (is (= {:name "myproject"
              :path "/home/user/projects/myproject"
              :action :use-existing}
             (core/build-project-plan
              {:type :project-name :name "myproject"}
              (assoc base-context :path-exists? (constantly true))))))

    (testing "project name with non-existent -> create dir"
      (is (= {:name "newproject"
              :path "/home/user/projects/newproject"
              :action :create-dir}
             (core/build-project-plan
              {:type :project-name :name "newproject"}
              base-context))))

    (testing "absolute path"
      (is (= {:name "api" :path "/absolute/path/api" :action :use-existing}
             (core/build-project-plan
              {:type :absolute-path :path "/absolute/path/api"}
              base-context))))))

;; =============================================================================
;; Time Formatting Tests
;; =============================================================================

(deftest format-time-ago-test
  (let [now 1000]
    (testing "seconds ago"
      (is (= "30s ago" (core/format-time-ago 970 now))))

    (testing "minutes ago"
      (is (= "5m ago" (core/format-time-ago 700 now))))

    (testing "one minute boundary"
      (is (= "1m ago" (core/format-time-ago 940 now))))

    (testing "hours ago"
      (is (= "2h ago" (core/format-time-ago (- now 7200) now))))

    (testing "days ago"
      (is (= "1d ago" (core/format-time-ago (- now 86400) now))))))

;; =============================================================================
;; Command Building Tests
;; =============================================================================

(deftest build-tmux-args-test
  (testing "new-session with all options"
    (is (= ["new-session" "-d" "-s" "claude-foo" "-c" "/tmp" "claude"]
           (core/build-tmux-args {:op :new-session
                                  :name "claude-foo"
                                  :path "/tmp"
                                  :cmd "claude"}))))

  (testing "new-session without cmd"
    (is (= ["new-session" "-d" "-s" "claude-foo" "-c" "/tmp"]
           (core/build-tmux-args {:op :new-session
                                  :name "claude-foo"
                                  :path "/tmp"}))))

  (testing "attach"
    (is (= ["attach" "-t" "claude-foo"]
           (core/build-tmux-args {:op :attach :name "claude-foo"}))))

  (testing "kill-session"
    (is (= ["kill-session" "-t" "claude-foo"]
           (core/build-tmux-args {:op :kill-session :name "claude-foo"}))))

  (testing "has-session"
    (is (= ["has-session" "-t" "claude-foo"]
           (core/build-tmux-args {:op :has-session :name "claude-foo"}))))

  (testing "list-sessions with format"
    (is (= ["ls" "-F" "#{session_name}"]
           (core/build-tmux-args {:op :list-sessions :format "#{session_name}"})))))
