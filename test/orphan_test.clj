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

(deftest brew-extra-packages-test
  (testing "a formula not declared is extra"
    (is (= #{"wget"} (brew/extra-packages {:formulae #{"neovim" "ripgrep" "wget"} :casks #{}}
                                          #{"neovim" "ripgrep"}))))

  (testing "only leaves are candidates, so no false positives"
    (is (empty? (brew/extra-packages {:formulae #{"neovim"} :casks #{}} #{"neovim"}))))

  (testing "a cask not declared is extra"
    (is (= #{"slack"} (brew/extra-packages {:formulae #{} :casks #{"firefox" "slack"}} #{"firefox"}))))

  (testing "tap-qualified: an installed full name is covered by a declared short name"
    (is (empty? (brew/extra-packages {:formulae #{"babashka/brew/bbin"} :casks #{}} #{"bbin"}))))

  (testing "tap-qualified: declared by full name"
    (is (empty? (brew/extra-packages {:formulae #{"babashka/brew/bbin" "borkdude/brew/babashka"} :casks #{}}
                                     #{"babashka/brew/bbin" "borkdude/brew/babashka"}))))

  (testing "tap-qualified: a mix of full and short names"
    (is (= #{"wget"} (brew/extra-packages {:formulae #{"babashka/brew/bbin" "neovim" "wget"} :casks #{}}
                                          #{"babashka/brew/bbin" "neovim"})))))

;; =============================================================================
;; Uninstall action implementations
;; =============================================================================

(defn- mock-exec!
  "Returns a mock exec! fn that tracks calls in `calls` atom."
  [calls]
  (fn [opts args]
    (swap! calls conj args)
    {:exit 0 :err nil}))

(deftest brew-remove-extras-test
  (testing "removing extras runs brew uninstall for each, then autoremove"
    (let [calls (atom [])]
      (with-redefs [a/exec! (mock-exec! calls)]
        (with-out-str (a/remove-extras! :pkg/brew {} [{:name "curl"} {:name "wget"}]
                                        (support/facts-of {[:brew :trusted] {:formulae #{} :taps #{}}}))))
      (is (= [["brew" "uninstall" "curl"] ["brew" "uninstall" "wget"] ["brew" "autoremove"]] @calls)))))

