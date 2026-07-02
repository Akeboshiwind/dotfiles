(ns spec-gap-test
  "Tests propagated from syn.allium where the spec deliberately outpaces the
   implementation. Each test asserts the SPECIFIED behaviour and is expected
   to FAIL until the code catches up — do not weaken a test to make it pass;
   fix the implementation (or, if intent changed, tend the spec and
   re-propagate). Spec constructs are cited per test."
  (:require [clojure.test :refer [deftest testing is use-fixtures]]
            [clojure.string :as str]
            [babashka.fs :as fs]
            [actions :as a]
            [check :as chk]
            [execute :as e]
            [graph :as g]
            [outcome :as o]
            [registry]))

(def ^:dynamic *tmp* nil)

(defn tmp-fixture [f]
  (let [dir (str (fs/create-temp-dir {:prefix "spec-gap-test-"}))]
    (binding [*tmp* dir]
      (try (f)
           (finally (fs/delete-tree dir))))))

(use-fixtures :each tmp-fixture)

;; =============================================================================
;; Spec: rule PersistSymlinkOwnership
;; "the cache's record of owned symlinks is replaced by the symlinks that
;;  verifiably exist as syn's: those newly created this run and those already
;;  satisfied ... syn never claims ownership of a link it did not make"
;; Gap: main.clj saves every planned symlink, failures included.
;; =============================================================================

(deftest symlink-ownership-excludes-failures-test
  (testing "only applied or already-satisfied symlinks are recorded as owned"
    (if-let [recordable (requiring-resolve 'execute/recordable-symlinks)]
      (let [good-src (str *tmp* "/good-src.txt")
            good-target (str *tmp* "/good-link.txt")
            bad-src (str *tmp* "/bad-src.txt")
            bad-target (str *tmp* "/existing-file.txt")]
        (spit good-src "a")
        (spit bad-src "b")
        (spit bad-target "already here")            ;; conflict: regular file at target
        (let [symlinks {good-target good-src
                        bad-target bad-src}
              ag (-> {:fs/symlink symlinks}
                     g/build-action-graph
                     chk/run-checks
                     e/execute-plan)]
          (is (= {good-target good-src} (recordable ag symlinks))
              "the conflicted symlink must not be recorded as owned")))
      (is false
          (str "execute/recordable-symlinks not implemented — main.clj caches every "
               "planned symlink, including failed/conflicted ones, so syn later tries "
               "to unlink links it never created (spec: rule PersistSymlinkOwnership)")))))

;; =============================================================================
;; Spec: surface RunReport, @guarantee ValidationVisibleBeforeApply
;; "Anything that would block an apply (duplicate declarations, empty secrets)
;;  is already visible in the plan report."
;; Gap: main.clj only prints validation errors in apply mode.
;; =============================================================================

(deftest plan-mode-surfaces-validation-errors-test
  (testing "plan mode reports the validation errors that would block an apply"
    (if-let [show (requiring-resolve 'status/show-validation-errors)]
      (let [out (with-out-str
                  (show [{:action :pkg/brew :key :htop :error "Defined in cfg/a, cfg/b"}]))]
        (is (str/includes? out "htop")
            "the offending key must appear in the plan output"))
      (is false
          (str "status/show-validation-errors not implemented — plan mode displays "
               "the plan without surfacing duplicate-declaration or secret errors "
               "(spec: rule DisplayPlan, @guarantee ValidationVisibleBeforeApply)")))))

;; =============================================================================
;; Spec: rule CheckClaudeResources
;; "Missing registration is drift/missing ... A present, current resource is
;;  satisfied and is not re-registered."
;; Gap: :claude/mcp has no check implementation, so it falls through to the
;; default (unknown) and every apply removes and re-adds each MCP server.
;; =============================================================================

(deftest claude-mcp-check-implemented-test
  (testing "MCP servers are checked for presence, not blindly re-registered"
    (is (not (o/unknown? (a/check :claude/mcp :spec-gap-server {:command "echo"})))
        "check :claude/mcp falls through to the default unknown outcome")))

;; =============================================================================
;; Spec: rule CheckDefaults
;; "Every declared value is compared against the live system, including array
;;  and dict values."
;; Gap: osx.clj skips map/vector values during comparison, so their drift is
;; invisible — even a domain that does not exist checks as satisfied.
;; =============================================================================

(deftest defaults-complex-values-compared-test
  (testing "array and dict values participate in drift detection"
    (let [result (a/check :osx/defaults :spec-gap
                          {:domain "com.syn.spec-gap.nonexistent"
                           :settings {:complex-array [1 2 3]
                                      :complex-dict {:a 1}}})]
      (is (o/drift? result)
          "complex values are skipped by the comparison, so a nonexistent domain checks as satisfied"))))

;; =============================================================================
;; Spec: rule CheckGitClones
;; "A repo with no declared ref is satisfied by mere existence, but the report
;;  warns the operator that it will never be updated."
;; Gap: the check returns plain satisfied with no message, so the plan report
;; has nothing to surface (and git.clj's update path for ref-less repos is
;; unreachable).
;; =============================================================================

(deftest git-refless-clone-warns-test
  (testing "a ref-less existing repo is satisfied but carries a warning message"
    (let [dir (str *tmp* "/refless-repo")]
      (fs/create-dirs dir)
      (let [result (a/check :git/clone dir {:url "https://example.com/r.git"})]
        (is (o/satisfied? result))
        (is (some? (:message result))
            "no warning message on a satisfied ref-less clone — the plan report cannot surface it")))))
