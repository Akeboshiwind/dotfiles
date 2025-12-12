(ns graph-test
  (:require [clojure.test :refer [deftest testing is]]
            [graph :as g]))

;; =============================================================================
;; Test Data
;; =============================================================================

(def simple-plan
  "Basic plan with no dependencies"
  {:fs/symlink {"~/.gitconfig" "./cfg/git/.gitconfig"
                "~/.zshrc" "./cfg/zsh/.zshrc"}
   :osx/defaults {:dock-autohide {:domain "com.apple.dock"
                                  :key "autohide"
                                  :value true}}})

(def bootstrap-plan
  "Plan with brew bootstrap and dependent packages"
  {:pkg/script {:homebrew {:src "./scripts/install-homebrew.sh"
                           :dep/provides #{:pkg/brew}}}
   :pkg/brew {:neovim {:head true}
              :ripgrep {}
              :mise {:dep/provides #{:pkg/mise}}}
   :pkg/mise {:node {:version "20" :global true}}})

(def full-plan
  "Complete plan with multiple dependency chains"
  {:pkg/script {:homebrew {:src "./scripts/install-homebrew.sh"
                           :dep/provides #{:pkg/brew}}}
   :osx/defaults {:dock-autohide {:domain "com.apple.dock"
                                  :key "autohide"
                                  :value true}}
   :fs/symlink {"~/.gitconfig" "./cfg/git/.gitconfig"}
   :pkg/brew {:mise {:dep/provides #{:pkg/mise}}
              :mas {:dep/provides #{:pkg/mas}}
              :bbin {:dep/provides #{:pkg/bbin}}
              :neovim {:head true}
              :claude-code {:dep/provides #{:claude/marketplace :claude/plugin}}}
   :pkg/mise {:node {:version "20"}}
   :pkg/mas {:things3 {:id 904280696}}
   :pkg/bbin {:jet {:lib "io.github.borkdude/jet"}}
   :claude/marketplace {:glittercowboy/taches-cc-resources {}}
   :claude/plugin {:taches {:dep/requires #{[:claude/marketplace :glittercowboy/taches-cc-resources]}}}})

(def cyclic-plan
  "Plan with a dependency cycle"
  {:pkg/brew {:a {:dep/provides #{:pkg/mise}}}
   :pkg/mise {:b {:dep/provides #{:pkg/brew}}}})

(def missing-provider-plan
  "Plan with a missing provider"
  {:pkg/mise {:node {:version "20"}}})

(def duplicate-provider-plan
  "Plan with duplicate providers for same capability"
  {:pkg/script {:homebrew-a {:dep/provides #{:pkg/brew}}
                :homebrew-b {:dep/provides #{:pkg/brew}}}})

;; =============================================================================
;; validate tests
;; =============================================================================

(deftest validate-test
  (testing "valid plans return nil"
    (is (nil? (g/validate simple-plan)))
    (is (nil? (g/validate bootstrap-plan)))
    (is (nil? (g/validate full-plan))))

  (testing "cyclic plan returns cycle error"
    (let [errors (g/validate cyclic-plan)]
      (is (some? errors))
      (is (some? (:cycles errors)))
      (is (= 1 (count (:cycles errors))))))

  (testing "missing provider returns missing error"
    (let [errors (g/validate missing-provider-plan)]
      (is (some? errors))
      (is (some? (:missing errors)))
      (is (= 1 (count (:missing errors))))
      (is (= :pkg/mise (:missing-capability (first (:missing errors)))))
      (is (= [:pkg/mise :node] (:action (first (:missing errors)))))))

  (testing "duplicate provider returns duplicate error"
    (let [errors (g/validate duplicate-provider-plan)]
      (is (some? errors))
      (is (some? (:duplicates errors)))
      (is (= 1 (count (:duplicates errors))))
      (is (= :pkg/brew (:capability (first (:duplicates errors)))))
      (is (= 2 (count (:providers (first (:duplicates errors))))))))

  (testing "empty plan is valid"
    (is (nil? (g/validate {})))))

;; =============================================================================
;; topological-sort tests
;; =============================================================================

(deftest topological-sort-test
  (testing "empty plan"
    (is (= [] (g/topological-sort {}))))

  (testing "no-dep actions sorted by type then key"
    (is (= [[:fs/symlink "~/.gitconfig"]
            [:fs/symlink "~/.zshrc"]
            [:osx/defaults :dock-autohide]]
           (g/topological-sort simple-plan))))

  (testing "bootstrap plan: deps first, then sorted"
    (is (= [;; :homebrew provides :pkg/brew
            [:pkg/script :homebrew]
            ;; :mise provides :pkg/mise
            [:pkg/brew :mise]
            [:pkg/brew :neovim]
            [:pkg/brew :ripgrep]
            [:pkg/mise :node]]
           (g/topological-sort bootstrap-plan))))

  (testing "full plan: complex dependency chains"
    (is (= [;; orphans first (no deps, nothing depends on them)
            [:fs/symlink "~/.gitconfig"]
            [:osx/defaults :dock-autohide]
            ;; :homebrew provides :pkg/brew
            [:pkg/script :homebrew]
            ;; :claude-code provides :claude/marketplace and :claude/plugin
            [:pkg/brew :claude-code]
            ;; :glittercowboy requires :claude/marketplace
            [:claude/marketplace :glittercowboy/taches-cc-resources]
            ;; :taches has explicit dep on :glittercowboy
            [:claude/plugin :taches]
            ;; :bbin provides :pkg/bbin
            [:pkg/brew :bbin]
            [:pkg/bbin :jet]
            ;; :mas provides :pkg/mas
            [:pkg/brew :mas]
            ;; :mise provides :pkg/mise
            [:pkg/brew :mise]
            [:pkg/brew :neovim]
            [:pkg/mas :things3]
            [:pkg/mise :node]]
           (g/topological-sort full-plan))))

  (testing "explicit requires on specific action"
    (let [plan {:pkg/script {:a {:dep/provides #{:pkg/brew}}}
                :pkg/brew {:b {}
                           :c {:dep/requires #{[:pkg/brew :b]}}}}]
      (is (= [;; :a provides :pkg/brew
              [:pkg/script :a]
              [:pkg/brew :b]
              ;; :c explicitly requires [:pkg/brew :b]
              [:pkg/brew :c]]
             (g/topological-sort plan))))))

;; =============================================================================
;; Edge cases
;; =============================================================================

(deftest edge-cases-test
  (testing "custom action types require their capability"
    (let [plan {:my/custom {:foo {}}}
          errors (g/validate plan)]
      (is (some? (:missing errors)))
      (is (= :my/custom (:missing-capability (first (:missing errors)))))))

  (testing "no-dep action types have no implicit requirements"
    (let [plan {:fs/symlink {"~/.foo" "./foo"}
                :fs/unlink {"~/.old" {}}
                :osx/defaults {:bar {:domain "com.example" :key "bar" :value 1}}
                :pkg/script {:baz {:src "./baz.sh"}}}]
      (is (nil? (g/validate plan)))
      (is (= [[:fs/symlink "~/.foo"]
              [:fs/unlink "~/.old"]
              [:osx/defaults :bar]
              [:pkg/script :baz]]
             (g/topological-sort plan))))))
