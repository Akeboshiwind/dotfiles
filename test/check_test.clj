(ns check-test
  (:require [clojure.test :refer [deftest testing is use-fixtures]]
            [babashka.fs :as fs]
            [babashka.process :as process]
            [clojure.string :as str]
            [actions :as a]
            [actions.claude :as claude]
            [cache :as c]
            [graph :as g]
            [outcome :as o]
            [registry]
            [status :as s]
            [support]))

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
      (is (o/satisfied? (support/check-live :fs/symlink target source))))))

(deftest symlink-check-missing-test
  (testing "target doesn't exist → drift(:missing)"
    (let [source (str *tmp* "/source.txt")
          target (str *tmp* "/nolink.txt")]
      (spit source "hello")
      (let [result (support/check-live :fs/symlink target source)]
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
      (let [result (support/check-live :fs/symlink target source)]
        (is (o/drift? result))
        (is (= :wrong (:kind result)))))))

(deftest symlink-check-regular-file-test
  (testing "regular file at target → conflict"
    (let [source (str *tmp* "/source.txt")
          target (str *tmp* "/file.txt")]
      (spit source "hello")
      (spit target "existing")
      (is (o/conflict? (support/check-live :fs/symlink target source))))))

;; =============================================================================
;; :fs/unlink check
;; =============================================================================

(deftest unlink-check-gone-test
  (testing "target doesn't exist → satisfied"
    (let [target (str *tmp* "/gone.txt")]
      (is (o/satisfied? (support/check-live :fs/unlink target "/some/source"))))))

(deftest unlink-check-stale-symlink-test
  (testing "valid stale symlink → drift(:orphan)"
    (let [source (str *tmp* "/source.txt")
          target (str *tmp* "/stale.txt")]
      (spit source "hello")
      (fs/create-sym-link target source)
      (let [result (support/check-live :fs/unlink target source)]
        (is (o/drift? result))
        (is (= :orphan (:kind result)))))))

(deftest unlink-check-not-symlink-test
  (testing "regular file at target → conflict"
    (let [target (str *tmp* "/file.txt")]
      (spit target "hello")
      (is (o/conflict? (support/check-live :fs/unlink target "/some/source"))))))

(deftest unlink-check-wrong-target-test
  (testing "symlink points elsewhere → conflict"
    (let [other (str *tmp* "/other.txt")
          target (str *tmp* "/link.txt")]
      (spit other "hello")
      (fs/create-sym-link target other)
      (is (o/conflict? (support/check-live :fs/unlink target "/expected/source"))))))

;; =============================================================================
;; :pkg/brew check
;; =============================================================================

(deftest brew-check-installed-test
  (testing "installed formula → satisfied"
    (let [facts (support/facts-of {[:brew :formulae] #{"neovim"} [:brew :casks] #{} [:brew :outdated] {}})]
      (is (o/satisfied? (a/check :pkg/brew :neovim {} facts))))))

(deftest brew-check-missing-test
  (testing "missing formula → drift(:missing)"
    (let [facts (support/facts-of {[:brew :formulae] #{} [:brew :casks] #{} [:brew :outdated] {}})]
      (let [result (a/check :pkg/brew :neovim {} facts)]
        (is (o/drift? result))
        (is (= :missing (:kind result)))))))

(deftest brew-check-outdated-test
  (testing "outdated formula → drift(:outdated) with version message"
    (let [facts (support/facts-of {[:brew :formulae] #{"neovim"} [:brew :casks] #{} [:brew :outdated] {"neovim" {:installed "0.9" :current "0.10"}}})]
      (let [result (a/check :pkg/brew :neovim {} facts)]
        (is (o/drift? result))
        (is (= :outdated (:kind result)))
        (is (= "0.9 → 0.10" (:message result)))))))

(deftest brew-check-tap-qualified-test
  (testing "tap-qualified package uses short name for lookup"
    (let [facts (support/facts-of {[:brew :formulae] #{"bbin"} [:brew :casks] #{} [:brew :outdated] {}})]
      (is (o/satisfied? (a/check :pkg/brew (keyword "babashka/brew/bbin") {} facts))))))

;; =============================================================================
;; :brew/service check
;; =============================================================================

(deftest service-check-running-test
  (testing "running service → satisfied"
    (let [facts (support/facts-of {[:brew :services] {"dnsmasq" {:name "dnsmasq" :status "started"}}})]
      (is (o/satisfied? (a/check :brew/service :dnsmasq {} facts))))))

(deftest service-check-stopped-test
  (testing "stopped service → drift(:missing)"
    (let [facts (support/facts-of {[:brew :services] {"dnsmasq" {:name "dnsmasq" :status "stopped"}}})]
      (let [result (a/check :brew/service :dnsmasq {} facts)]
        (is (o/drift? result))
        (is (= :missing (:kind result)))))))

(deftest service-check-missing-test
  (testing "unknown service → drift(:missing)"
    (let [facts (support/facts-of {[:brew :services] {}})]
      (let [result (a/check :brew/service :dnsmasq {} facts)]
        (is (o/drift? result))
        (is (= :missing (:kind result)))))))

;; =============================================================================
;; :assert check
;; =============================================================================

(deftest assert-check-satisfied-test
  (testing "assertion passes → satisfied"
    (is (o/satisfied? (support/check-live :assert :test-assert {:src "exit 0"})))))

(deftest assert-check-failed-test
  (testing "assertion fails → error"
    (is (o/error? (support/check-live :assert :test-assert {:src "exit 1"})))))

(deftest assert-check-no-script-test
  (testing "no :path or :src → error"
    (is (o/error? (support/check-live :assert :test-assert {})))))

(deftest assert-check-custom-message-test
  (testing "custom message in error"
    (let [result (support/check-live :assert :test-assert {:src "exit 1" :message "Remote Login disabled"})]
      (is (o/error? result))
      (is (= "Remote Login disabled" (:message result))))))

;; =============================================================================
;; :pkg/script check
;; =============================================================================

(deftest script-check-no-check-key-test
  (testing "script without :check key → unknown"
    (is (o/unknown? (support/check-live :pkg/script :setup {:src "echo hello"})))))

(deftest script-check-with-check-passes-test
  (testing "script with :check that passes → satisfied"
    (is (o/satisfied? (support/check-live :pkg/script :setup {:src "echo hello" :check {:src "exit 0"}})))))

(deftest script-check-content-changed-test
  (testing "DOTFILES_CONTENT_CHANGED=true when no cached record"
    (reset! a/*cache* {})
    (is (o/satisfied?
          (support/check-live :pkg/script :test-script
                   {:src "echo ok"
                    :check {:src "test \"$DOTFILES_CONTENT_CHANGED\" = \"true\""}}))))

  (testing "DOTFILES_CONTENT_CHANGED=false when content unchanged"
    (let [content "echo ok"
          record (c/script-record content)]
      (reset! a/*cache* {:scripts {"test-script" record}})
      (is (o/satisfied?
            (support/check-live :pkg/script :test-script
                     {:src content
                      :check {:src "test \"$DOTFILES_CONTENT_CHANGED\" = \"false\""}})))))

  (testing "DOTFILES_CONTENT_CHANGED=true when content changed"
    (let [old-record (c/script-record "old content")]
      (reset! a/*cache* {:scripts {"test-script" old-record}})
      (is (o/satisfied?
            (support/check-live :pkg/script :test-script
                     {:src "new content"
                      :check {:src "test \"$DOTFILES_CONTENT_CHANGED\" = \"true\""}})))
      ;; Clean up
      (reset! a/*cache* nil))))

(deftest script-check-with-check-fails-test
  (testing "script with :check that fails → drift(:missing)"
    (let [result (support/check-live :pkg/script :setup {:src "echo hello" :check {:src "exit 1"}})]
      (is (o/drift? result))
      (is (= :missing (:kind result))))))

(deftest script-check-no-script-test
  (testing "no :path or :src → error"
    (is (o/error? (support/check-live :pkg/script :setup {})))))

;; =============================================================================
;; :pkg/mise check
;; =============================================================================

(deftest mise-check-outdated-test
  (testing "outdated tool → drift(:outdated) with version message"
    (let [facts (support/facts-of {[:mise :installed] {"node" #{"18.0.0" "20.0.0"}}})]
      (let [result (a/check :pkg/mise :node {:version "22.0.0"} facts)]
        (is (o/drift? result))
        (is (= :outdated (:kind result)))
        (is (= "20.0.0 → 22.0.0" (:message result)))))))

(deftest mise-check-version-required-test
  (testing "mise tool declared without version → error"
    (is (o/error? (a/check :pkg/mise :node {} {})))))

(deftest mise-check-pinned-satisfied-test
  (testing "pinned version installed → satisfied"
    (let [facts (support/facts-of {[:mise :installed] {"node" #{"20.0.0"}}})]
      (is (o/satisfied? (a/check :pkg/mise :node {:version "20.0.0"} facts))))))

(deftest mise-check-missing-test
  (testing "tool not installed → drift(:missing)"
    (let [facts (support/facts-of {[:mise :installed] {}})]
      (let [result (a/check :pkg/mise :node {:version "20.0.0"} facts)]
        (is (o/drift? result))
        (is (= :missing (:kind result)))))))

(deftest mise-check-latest-current-test
  (testing "latest requested, no upgrade available → satisfied"
    (let [facts (support/facts-of {[:mise :installed] {"node" #{"20.0.0"}} [:mise :outdated] {}})]
      (is (o/satisfied? (a/check :pkg/mise :node {:version "latest"} facts))))))

(deftest mise-check-latest-outdated-test
  (testing "latest requested, upgrade available → drift(:outdated) with version message"
    (let [facts (support/facts-of {[:mise :installed] {"node" #{"20.0.0"}} [:mise :outdated] {"node" {:current "20.0.0" :latest "22.0.0"}}})]
      (let [result (a/check :pkg/mise :node {:version "latest"} facts)]
        (is (o/drift? result))
        (is (= :outdated (:kind result)))
        (is (= "20.0.0 → 22.0.0" (:message result)))))))

;; =============================================================================
;; :pkg/npm check
;; =============================================================================

(deftest npm-check-test
  (let [facts (support/facts-of {[:npm :installed] #{"happy-coder" "prettier"}
                                 [:npm :outdated] {"prettier" {:current "3.0.0" :latest "3.1.0"}}})]
    (testing "installed → satisfied"
      (is (o/satisfied? (a/check :pkg/npm :happy-coder {} facts))))
    (testing "a tarball URL is checked by the package name in its filename"
      (is (o/satisfied? (a/check :pkg/npm "https://example.com/happy-coder-0.13.0.tgz" {} facts))))
    (testing "outdated → drift(:outdated) with version message"
      (is (= "3.0.0 → 3.1.0" (:message (a/check :pkg/npm :prettier {} facts)))))
    (testing "absent → drift(:missing)"
      (is (= :missing (:kind (a/check :pkg/npm :typescript {} facts)))))))

;; =============================================================================
;; :pkg/mas check
;; =============================================================================

(deftest mas-check-installed-test
  (testing "installed app → satisfied"
    (let [facts (support/facts-of {[:mas :installed] {1295203466 "Windows App"}})]
      (is (o/satisfied? (a/check :pkg/mas 1295203466 "Windows App" facts))))))

(deftest mas-check-missing-test
  (testing "app not installed → drift(:missing)"
    (let [facts (support/facts-of {[:mas :installed] {}})]
      (let [result (a/check :pkg/mas 1295203466 "Windows App" facts)]
        (is (o/drift? result))
        (is (= :missing (:kind result)))))))

(deftest mas-plan-label-test
  (testing "a mas app reads by its name in the plan, not its id"
    (let [ag (-> (g/build-action-graph {:pkg/script {:mas {:dep/provides #{:pkg/mas}}}
                                        :pkg/mas {1295203466 "Windows App"}})
                 (assoc-in [:nodes [:pkg/mas 1295203466] :check] (o/drift :missing))
                 (assoc-in [:nodes [:pkg/script :mas] :check] o/satisfied))
          out (with-out-str (s/show-plan ag))]
      (is (re-find #"Windows App" out))
      (is (not (re-find #"1295203466" out))))))

(deftest mas-check-old-shape-test
  (testing "an app declared {name id} is an error, not a missing app"
    (let [result (a/check :pkg/mas "Windows App" 1295203466 (support/facts-of {[:mas :installed] {}}))]
      (is (o/error? result))
      (is (re-find #"\{app-id name\}" (:message result))))))

;; =============================================================================
;; :git/clone check
;; =============================================================================

(defn- init-repo!
  "Create a git repo with one commit at dir, return its HEAD sha."
  [dir]
  (process/shell {:out :string :err :string} "git" "init" "-q" dir)
  (process/shell {:out :string :err :string :dir dir}
                 "git" "-c" "user.email=t@t" "-c" "user.name=t"
                 "commit" "--allow-empty" "-q" "-m" "init")
  (-> (process/shell {:out :string :err :string :dir dir} "git" "rev-parse" "HEAD")
      :out
      str/trim))

(deftest git-clone-check-missing-test
  (testing "no directory at target → drift(:missing)"
    (let [result (support/check-live :git/clone (str *tmp* "/norepo") {:url "https://example.com/r.git"})]
      (is (o/drift? result))
      (is (= :missing (:kind result))))))

(deftest git-clone-check-ref-match-test
  (testing "repo at the declared ref → satisfied"
    (let [dir (str *tmp* "/repo")
          sha (init-repo! dir)]
      (is (o/satisfied? (support/check-live :git/clone dir {:url "ignored" :ref sha}))))))

(deftest git-clone-check-ref-mismatch-test
  (testing "repo at a different ref → drift(:outdated)"
    (let [dir (str *tmp* "/repo2")]
      (init-repo! dir)
      (let [result (support/check-live :git/clone dir {:url "ignored" :ref "0000000000"})]
        (is (o/drift? result))
        (is (= :outdated (:kind result)))))))

(deftest git-clone-check-refless-exists-test
  (testing "existing directory with no declared ref → satisfied"
    (let [dir (str *tmp* "/repo3")]
      (fs/create-dirs dir)
      (is (o/satisfied? (support/check-live :git/clone dir {:url "ignored"}))))))

;; =============================================================================
;; :claude/marketplace and :claude/plugin checks
;; =============================================================================

(deftest claude-marketplace-check-test
  (testing "registered marketplace → satisfied; unregistered → drift"
    (let [facts (support/facts-of {[:claude :marketplaces] {:jx {:source {:repo "juxt/plugins"}}}})]
      (is (o/satisfied? (a/check :claude/marketplace :plugins {:source "juxt/plugins"} facts)))
      (is (o/drift? (a/check :claude/marketplace :other {:source "acme/other"} facts))))))

(deftest claude-plugin-check-test
  (testing "installed and current plugin → satisfied; missing → drift"
    (let [facts (support/facts-of {[:claude :plugins] {(keyword "chalk@juxt-plugins") [{:version "0.11.2"}]}
                                   [:claude :catalogue "chalk"] "0.11.2"})]
      (is (o/satisfied? (a/check :claude/plugin :chalk {} facts)))
      (is (o/drift? (a/check :claude/plugin :missing-plugin {} facts))))))

(deftest claude-plugin-outdated-test
  (testing "installed plugin behind the refreshed marketplace catalogue → drift(:outdated)"
    (let [facts (support/facts-of {[:claude :plugins] {(keyword "chalk@juxt-plugins") [{:version "0.11.2"}]}
                                   [:claude :catalogue "chalk"] "0.12.0"})
          result (a/check :claude/plugin :chalk {} facts)]
      (is (o/drift? result))
      (is (= :outdated (:kind result)))
      (is (= "0.11.2 → 0.12.0" (:message result))))))

(deftest claude-plugin-catalogue-query-test
  (testing "the catalogue is refreshed, then read, only for an installed plugin"
    (let [refreshed (atom 0)]
      (with-bindings {#'claude/*marketplace-refresh* (delay (swap! refreshed inc))}
        (with-redefs [claude/installed-plugins (fn [] {(keyword "chalk@juxt-plugins") [{:version "0.11.2"}]})
                      claude/catalogue-version (fn [mp n] (when (= [mp n] ["juxt-plugins" "chalk"]) "0.12.0"))]
          (is (nil? (a/run-query [:claude :catalogue "missing-plugin"])))
          (is (zero? @refreshed) "no installed plugin, no network refresh")
          (is (= "0.12.0" (a/run-query [:claude :catalogue "chalk"])))
          (is (= 1 @refreshed)))))))

(deftest claude-mcp-check-test
  (testing "user-scope server present → satisfied; absent → drift(:missing)"
    (let [facts (support/facts-of {[:claude :mcp] {:my-server {:command "x"}}})]
      (is (o/satisfied? (a/check :claude/mcp :my-server {:command "x"} facts)))
      (let [result (a/check :claude/mcp :other {:command "x"} facts)]
        (is (o/drift? result))
        (is (= :missing (:kind result))))))

  (testing "non-user scope → error (syn manages machine-global state only)"
    (is (o/error? (a/check :claude/mcp :proj {:command "x" :scope "project"} {})))
    (is (o/error? (a/check :claude/mcp :loc {:command "x" :scope "local"} {})))))

(deftest claude-plugin-update-command-test
  (testing "outdated plugin updates via its marketplace-qualified id (bare name → 'not found')"
    (let [calls (atom [])]
      (with-redefs [a/exec! (fn [_ args] (swap! calls conj args) {:exit 0 :err nil})]
        (a/install! :claude/plugin {} {:allium {}}
                    (support/facts-of {[:claude :plugins] {(keyword "allium@juxt-plugins") [{:version "3.6.0"}]}})))
      (is (some #(= ["claude" "plugin" "update" "allium@juxt-plugins"] %) @calls))))

  (testing "missing plugin installs by bare name"
    (let [calls (atom [])]
      (with-redefs [a/exec! (fn [_ args] (swap! calls conj args) {:exit 0 :err nil})]
        (a/install! :claude/plugin {} {:allium {}} (support/facts-of {[:claude :plugins] {}})))
      (is (some #(= ["claude" "plugin" "install" "allium"] %) @calls)))))

(deftest claude-plugin-unknown-catalogue-version-test
  (testing "installed plugin with no catalogue version → satisfied (cannot determine drift)"
    (is (o/satisfied? (a/check :claude/plugin :chalk {}
                               (support/facts-of {[:claude :plugins] {(keyword "chalk@juxt-plugins") [{:version "0.11.2"}]}
                                                  [:claude :catalogue "chalk"] nil}))))))

;; =============================================================================
;; Default check (unknown for unimplemented types)
;; =============================================================================

(deftest default-check-unknown-test
  (testing "unimplemented action type → unknown"
    (is (o/unknown? (a/check :some/unimplemented :foo {} {})))))
