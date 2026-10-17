(ns orphan-test
  (:require [clojure.test :refer [deftest testing is]]
            [clojure.string :as str]
            [actions :as a]
            [actions.brew :as brew]
            [graph :as g]
            [plan :as p]
            [utils :as u]
            ;; Load action impls
            [execute]
            [support]))

;; =============================================================================
;; brew deps-graph parsing
;; =============================================================================

(deftest deps-graph-test
  (testing "parses brew deps --installed output into adjacency map"
    (let [output "neovim: gettext libuv luajit luv msgpack tree-sitter unibilium\nripgrep: pcre2\ngit: gettext pcre2"]
      (is (= {"neovim" #{"gettext" "libuv" "luajit" "luv" "msgpack" "tree-sitter" "unibilium"}
              "ripgrep" #{"pcre2"}
              "git" #{"gettext" "pcre2"}}
             (brew/parse-deps-graph output)))))

  (testing "empty output returns empty map"
    (is (= {} (brew/parse-deps-graph ""))))

  (testing "package with no deps returns empty set"
    (is (= {"wget" #{}}
           (brew/parse-deps-graph "wget:")))))

;; =============================================================================
;; transitive deps closure
;; =============================================================================

(deftest transitive-deps-of-test
  (testing "computes transitive closure of declared packages"
    (let [graph {"neovim" #{"luajit" "gettext"}
                 "luajit" #{"readline"}
                 "git" #{"pcre2" "gettext"}
                 "pcre2" #{}
                 "gettext" #{}
                 "readline" #{}}]
      ;; declared: neovim, git
      ;; neovim -> luajit, gettext; luajit -> readline
      ;; git -> pcre2, gettext
      ;; closure = luajit gettext readline pcre2
      (is (= #{"luajit" "gettext" "readline" "pcre2"}
             (brew/transitive-deps-of #{"neovim" "git"} graph)))))

  (testing "empty declared returns empty deps"
    (is (= #{} (brew/transitive-deps-of #{} {"a" #{"b"}}))))

  (testing "declared package not in graph returns empty deps"
    (is (= #{} (brew/transitive-deps-of #{"unknown"} {"a" #{"b"}})))))

;; =============================================================================
;; orphans — per-action orphan detection
;; =============================================================================

(deftest brew-orphans-test
  (testing "formula not in manifest is orphaned"
    (let [result (brew/orphans {:formulae #{"neovim" "ripgrep" "wget"} :casks #{}}
                               {:neovim {} :ripgrep {}})]
      (is (= {"wget" {}} result))))

  (testing "only leaves are candidates, so no false positives"
    (let [result (brew/orphans {:formulae #{"neovim"} :casks #{}}
                               {:neovim {}})]
      (is (empty? result))))

  (testing "cask not in manifest is orphaned"
    (let [result (brew/orphans {:formulae #{} :casks #{"firefox" "slack"}}
                               {:firefox {:cask true}})]
      (is (= {"slack" {}} result))))

  (testing "no orphans returns empty"
    (let [result (brew/orphans {:formulae #{"neovim" "ripgrep"} :casks #{}}
                               {:neovim {} :ripgrep {}})]
      (is (empty? result))))

  (testing "tap-qualified: installed full-name matched by manifest short name"
    (let [result (brew/orphans {:formulae #{"babashka/brew/bbin"} :casks #{}}
                               {:bbin {}})]
      (is (empty? result))))

  (testing "tap-qualified: manifest uses full-name string key"
    (let [result (brew/orphans {:formulae #{"babashka/brew/bbin" "borkdude/brew/babashka"} :casks #{}}
                               {"babashka/brew/bbin" {} "borkdude/brew/babashka" {}})]
      (is (empty? result))))

  (testing "tap-qualified: mix of string and keyword keys"
    (let [result (brew/orphans {:formulae #{"babashka/brew/bbin" "neovim" "wget"} :casks #{}}
                               {"babashka/brew/bbin" {} :neovim {}})]
      (is (= {"wget" {}} result)))))

;; =============================================================================
;; Uninstall action implementations
;; =============================================================================

(defn- mock-exec!
  "Returns a mock exec! fn that tracks calls in `calls` atom."
  [calls]
  (fn [opts args]
    (swap! calls conj args)
    {:exit 0 :err nil}))

(deftest brew-uninstall-action-test
  (testing ":pkg/brew-uninstall runs brew uninstall for each item plus autoremove"
    (let [calls (atom [])]
      (with-redefs [a/exec! (mock-exec! calls)]
        (a/install! :pkg/brew-uninstall {} {"wget" {} "curl" {}} {}))
      (is (some #(= ["brew" "uninstall" "wget"] %) @calls))
      (is (some #(= ["brew" "uninstall" "curl"] %) @calls))
      (is (some #(= ["brew" "autoremove"] %) @calls))))

  (testing ":pkg/brew-uninstall requires [:complete :pkg/brew]"
    (is (= [:complete :pkg/brew] (a/requires :pkg/brew-uninstall)))))

;; =============================================================================
;; Graph ordering: uninstalls before installs
;; =============================================================================

;; =============================================================================
;; build! integration: orphans appear in plan
;; =============================================================================

(deftest build-includes-orphans-test
  ;; a/orphans is a multimethod that plan/calculate-orphans introspects with
  ;; (methods a/orphans), so it cannot be with-redefs'd to a plain fn — mock
  ;; the per-type helpers the implementations call instead.
  (testing "build! adds uninstall actions from a/orphans to plan"
    (let [entries [{:step {:pkg/script {:homebrew {:src "echo ok" :dep/provides #{:pkg/brew}}}
                           :pkg/brew {:jq {}}}}
                   :source "/test"]
          ;; Only brew's orphan detection runs; it sees "wget" as undeclared
          result (with-redefs [u/command-exists? (fn [cmd] (= cmd "brew"))
                               brew/leaves-set (fn [] #{"jq" "wget"})
                               brew/installed-set-full (fn [_] #{})
                               brew/installed-taps (fn [] #{})]
                   (p/build! entries {} nil))]
      (is (= {"wget" {}} (get-in result [:plan :pkg/brew-uninstall])))
      (let [ag (g/build-action-graph (:plan result))]
        (is (some #{[:pkg/brew-uninstall "wget"]} (:order ag))))))

  (testing "build! does not add uninstall actions when no orphans"
    (let [entries [{:step {:pkg/script {:homebrew {:src "echo ok" :dep/provides #{:pkg/brew}}}
                           :pkg/brew {:jq {}}}}
                   :source "/test"]
          result (with-redefs [u/command-exists? (constantly false)]
                   (p/build! entries {} nil))]
      (is (nil? (get-in result [:plan :pkg/brew-uninstall]))))))

(deftest uninstall-ordering-test
  (testing "uninstall actions sort after their install counterparts ([:complete type] dep)"
    (let [plan {:pkg/brew-uninstall {:wget {}}
                :pkg/brew {:neovim {}}
                :pkg/script {:homebrew {:dep/provides #{:pkg/brew}}}}
          order (g/topological-sort plan)]
      ;; script (provides :pkg/brew), then brew (requires :pkg/brew),
      ;; then brew-uninstall (requires [:complete :pkg/brew])
      (let [positions (into {} (map-indexed (fn [i a] [a i])) order)]
        (is (> (positions [:pkg/brew-uninstall :wget])
               (positions [:pkg/brew :neovim])))))))

(deftest orphan-types-for-scope-test
  (testing "an unscoped run detects orphans for every type that has detection"
    (is (= #{:pkg/brew}
           (set (p/orphan-types-for nil)))))
  (testing "a scoped run detects only the orphans it could act on"
    (is (empty? (p/orphan-types-for :fs/symlink)))
    (is (= [:pkg/brew] (p/orphan-types-for :pkg/brew)))
    (is (= [:pkg/brew] (p/orphan-types-for :brew/untap)) "taps come from brew's detection")
    (is (= [:pkg/brew] (p/orphan-types-for :pkg/brew-uninstall)))))
