(ns graph-test
  (:require [clojure.test :refer [deftest testing is]]
            [graph :as g]
            ;; Load action implementations so a/requires works
            [execute]))

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
  (testing "unknown action types require their capability"
    (let [plan {:my/custom {:foo {}}}
          errors (g/validate plan)]
      (is (some? (:missing errors)))
      (is (= :my/custom (:missing-capability (first (:missing errors)))))))

  (testing "standalone action types have no implicit requirements"
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

;; =============================================================================
;; transitive-deps tests
;; =============================================================================

(deftest transitive-deps-test
  (testing "empty targets returns empty set"
    (is (= #{} (g/transitive-deps bootstrap-plan #{}))))

  (testing "no-dep actions return only themselves"
    (is (= #{[:fs/symlink "~/.gitconfig"]}
           (g/transitive-deps simple-plan #{[:fs/symlink "~/.gitconfig"]}))))

  (testing "single level dependency"
    ;; :pkg/brew :neovim only requires :pkg/brew (provided by :pkg/script :homebrew)
    ;; It doesn't chain further
    (is (= #{[:pkg/brew :neovim] [:pkg/script :homebrew]}
           (g/transitive-deps bootstrap-plan #{[:pkg/brew :neovim]}))))

  (testing "transitive chain: mise -> brew -> script"
    ;; :pkg/mise :node requires :pkg/mise (provided by :pkg/brew :mise)
    ;; :pkg/brew :mise requires :pkg/brew (provided by :pkg/script :homebrew)
    (is (= #{[:pkg/mise :node]
             [:pkg/brew :mise]
             [:pkg/script :homebrew]}
           (g/transitive-deps bootstrap-plan #{[:pkg/mise :node]}))))

  (testing "multiple targets with shared deps"
    ;; Both mise actions share the same dependency chain
    (let [plan {:pkg/script {:homebrew {:dep/provides #{:pkg/brew}}}
                :pkg/brew {:mise {:dep/provides #{:pkg/mise}}}
                :pkg/mise {:node {} :python {}}}]
      (is (= #{[:pkg/mise :node]
               [:pkg/mise :python]
               [:pkg/brew :mise]
               [:pkg/script :homebrew]}
             (g/transitive-deps plan #{[:pkg/mise :node] [:pkg/mise :python]})))))

  (testing "explicit requires on specific action"
    (let [plan {:pkg/script {:a {:dep/provides #{:pkg/brew}}}
                :pkg/brew {:b {}
                           :c {:dep/requires #{[:pkg/brew :b]}}}}]
      ;; :c explicitly requires [:pkg/brew :b], which requires :pkg/brew
      (is (= #{[:pkg/brew :c]
               [:pkg/brew :b]
               [:pkg/script :a]}
             (g/transitive-deps plan #{[:pkg/brew :c]}))))))

;; =============================================================================
;; filter-order tests
;; =============================================================================

(deftest filter-order-test
  (testing "filters to action type with dependencies in correct order"
    (let [order (g/topological-sort bootstrap-plan)]
      ;; Should be: script first, then brew, then mise
      (is (= [[:pkg/script :homebrew]
              [:pkg/brew :mise]
              [:pkg/mise :node]]
             (g/filter-order bootstrap-plan order :pkg/mise)))))

  (testing "complex chain maintains dependency order"
    (let [order (g/topological-sort full-plan)]
      ;; Verify order: script -> brew -> marketplace -> plugin
      (is (= [[:pkg/script :homebrew]
              [:pkg/brew :claude-code]
              [:claude/marketplace :glittercowboy/taches-cc-resources]
              [:claude/plugin :taches]]
             (g/filter-order full-plan order :claude/plugin)))))

  (testing "multiple targets from same type share dependencies"
    (let [plan {:pkg/script {:homebrew {:dep/provides #{:pkg/brew}}}
                :pkg/brew {:mise {:dep/provides #{:pkg/mise}}
                           :other {}}
                :pkg/mise {:node {} :python {}}}
          order (g/topological-sort plan)
          filtered (g/filter-order plan order :pkg/mise)]
      ;; Both mise packages share the same deps
      (is (= [[:pkg/script :homebrew]
              [:pkg/brew :mise]
              [:pkg/mise :node]
              [:pkg/mise :python]]
             filtered))
      ;; :pkg/brew :other should NOT be included
      (is (not (some #{[:pkg/brew :other]} filtered)))))

  (testing "no-dep action type returns only those actions"
    (is (= [[:fs/symlink "~/.gitconfig"]
            [:fs/symlink "~/.zshrc"]]
           (g/filter-order simple-plan (g/topological-sort simple-plan) :fs/symlink)))))
