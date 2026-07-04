(ns stored-plan-test
  "Tests propagated from syn.allium for the stored-plan feature: a plan-mode
   run captures its checked plan so a following apply replays it without
   re-running the expensive live check phase.

   These assert the SPECIFIED behaviour and are expected to FAIL until the
   implementation catches up — do not weaken a test to make it pass; fix the
   implementation (or, if intent changed, tend the spec and re-propagate).
   Spec constructs are cited per section."
  (:require [clojure.test :refer [deftest testing is]]
            [stored-plan :as sp]))

;; A captured plan, as persisted. `now` is epoch-millis so temporal checks are
;; deterministic (spec: StoredPlan.captured_at : Timestamp, checked against
;; `now` — no wall-clock sleeping).
(def ^:private t0 1000000000000)                 ;; a fixed "capture" instant
(def ^:private ttl-ms (* 5 60 1000))             ;; spec: config.plan_ttl = 5.minutes

(defn- plan-at
  ([identity scope] (plan-at identity scope t0))
  ([identity scope captured-at]
   {:manifest-identity identity
    :scope scope
    :spent false
    :captured-at captured-at
    :plan {:some :plan}}))

;; =============================================================================
;; Spec: entity StoredPlan, derived `valid_for(current_identity, current_scope)`
;;   not spent AND manifest_identity = current AND scope matches AND within TTL
;; The single predicate both ReplayStoredPlan and ApplyWithoutValidPlanAborts
;; consult, so it is the crux of the feature's correctness.
;; =============================================================================

(deftest valid?-all-conditions-hold-test
  (testing "a fresh, matching, unspent, in-window plan is valid"
    (is (true? (sp/valid? (plan-at "abc" nil)
                          {:manifest-identity "abc" :scope nil
                           :now (+ t0 1000) :ttl-ms ttl-ms})))))

(deftest valid?-spent-test
  (testing "a spent plan is never valid (spec: SpendStoredPlanOnApply)"
    (is (false? (sp/valid? (assoc (plan-at "abc" nil) :spent true)
                           {:manifest-identity "abc" :scope nil
                            :now (+ t0 1000) :ttl-ms ttl-ms})))))

(deftest valid?-manifest-identity-mismatch-test
  (testing "a plan built from a different manifest is invalid (manifest edited)"
    (is (false? (sp/valid? (plan-at "abc" nil)
                           {:manifest-identity "xyz" :scope nil
                            :now (+ t0 1000) :ttl-ms ttl-ms})))))

(deftest valid?-scope-match-test
  (testing "scope must match: both nil"
    (is (true? (sp/valid? (plan-at "abc" nil)
                          {:manifest-identity "abc" :scope nil
                           :now (+ t0 1000) :ttl-ms ttl-ms}))))
  (testing "scope must match: same scope"
    (is (true? (sp/valid? (plan-at "abc" :pkg/brew)
                          {:manifest-identity "abc" :scope :pkg/brew
                           :now (+ t0 1000) :ttl-ms ttl-ms}))))
  (testing "scoped plan is invalid for an unscoped apply"
    (is (false? (sp/valid? (plan-at "abc" :pkg/brew)
                           {:manifest-identity "abc" :scope nil
                            :now (+ t0 1000) :ttl-ms ttl-ms}))))
  (testing "unscoped plan is invalid for a scoped apply"
    (is (false? (sp/valid? (plan-at "abc" nil)
                           {:manifest-identity "abc" :scope :pkg/brew
                            :now (+ t0 1000) :ttl-ms ttl-ms}))))
  (testing "different scopes do not match"
    (is (false? (sp/valid? (plan-at "abc" :pkg/brew)
                           {:manifest-identity "abc" :scope :fs/symlink
                            :now (+ t0 1000) :ttl-ms ttl-ms})))))

(deftest valid?-ttl-window-test
  (testing "a plan captured just inside the TTL is valid"
    (is (true? (sp/valid? (plan-at "abc" nil)
                          {:manifest-identity "abc" :scope nil
                           :now (+ t0 ttl-ms -1) :ttl-ms ttl-ms}))))
  (testing "a plan captured exactly at the TTL boundary is valid (<=)"
    (is (true? (sp/valid? (plan-at "abc" nil)
                          {:manifest-identity "abc" :scope nil
                           :now (+ t0 ttl-ms) :ttl-ms ttl-ms}))))
  (testing "a plan captured beyond the TTL is invalid (drift caught by clock)"
    (is (false? (sp/valid? (plan-at "abc" nil)
                           {:manifest-identity "abc" :scope nil
                            :now (+ t0 ttl-ms 1) :ttl-ms ttl-ms})))))

(deftest valid?-nil-plan-test
  (testing "no captured plan is not valid"
    (is (false? (sp/valid? nil
                           {:manifest-identity "abc" :scope nil
                            :now t0 :ttl-ms ttl-ms})))))

;; =============================================================================
;; Spec: rule ReplayStoredPlan (valid plan -> applying, skip checks),
;;       rule ApplyWithoutValidPlanAborts (no valid plan -> aborted),
;;       Run.fresh (--fresh bypasses the stored plan and checks live).
;; Modelled as one pure routing decision so the orchestration stays thin.
;; =============================================================================

(deftest plan-source-replay-test
  (testing "default apply with a valid stored plan replays it"
    (is (= :replay (sp/plan-source {:fresh? false
                                    :stored-plan (plan-at "abc" nil)
                                    :manifest-identity "abc" :scope nil
                                    :now (+ t0 1000) :ttl-ms ttl-ms})))))

(deftest plan-source-refuse-test
  (testing "default apply with no valid plan refuses (spec: ApplyWithoutValidPlanAborts)"
    (is (= :refuse (sp/plan-source {:fresh? false
                                    :stored-plan nil
                                    :manifest-identity "abc" :scope nil
                                    :now t0 :ttl-ms ttl-ms})))
    (is (= :refuse (sp/plan-source {:fresh? false
                                    :stored-plan (plan-at "abc" nil)
                                    :manifest-identity "xyz" :scope nil ;; manifest changed
                                    :now (+ t0 1000) :ttl-ms ttl-ms}))
        "a stale/mismatched plan refuses, it does not fall back to a live check")
    (is (= :refuse (sp/plan-source {:fresh? false
                                    :stored-plan (plan-at "abc" nil)
                                    :manifest-identity "abc" :scope nil
                                    :now (+ t0 ttl-ms 1) :ttl-ms ttl-ms})) ;; expired
        "an expired plan refuses")))

(deftest plan-source-fresh-test
  (testing "--fresh bypasses the stored plan entirely and checks live"
    (is (= :fresh (sp/plan-source {:fresh? true
                                   :stored-plan (plan-at "abc" nil)
                                   :manifest-identity "abc" :scope nil
                                   :now (+ t0 1000) :ttl-ms ttl-ms}))
        "even with a perfectly valid plan present, --fresh ignores it")
    (is (= :fresh (sp/plan-source {:fresh? true
                                   :stored-plan nil
                                   :manifest-identity "abc" :scope nil
                                   :now t0 :ttl-ms ttl-ms}))
        "--fresh works on a fresh checkout with no plan")))

;; =============================================================================
;; Spec: rule PersistCheckedPlan — capture the checked plan tagged with the
;; manifest identity and scope in force; it starts unspent, stamped `now`.
;; =============================================================================

(deftest capture-test
  (testing "capture builds a record tagged with identity, scope, capture time"
    (let [cap (sp/capture {:plan {:a 1} :manifest-identity "abc"
                           :scope :pkg/brew :now t0})]
      (is (= "abc" (:manifest-identity cap)))
      (is (= :pkg/brew (:scope cap)))
      (is (= t0 (:captured-at cap)))
      (is (= {:a 1} (:plan cap)))
      (is (false? (:spent cap)) "a freshly captured plan is unspent")))
  (testing "a captured plan is immediately valid for the same invocation"
    (let [cap (sp/capture {:plan {} :manifest-identity "abc" :scope nil :now t0})]
      (is (true? (sp/valid? cap {:manifest-identity "abc" :scope nil
                                 :now t0 :ttl-ms ttl-ms}))))))

;; =============================================================================
;; Spec: rule SpendStoredPlanOnApply — a completed apply consumes the plan, so
;; a second bare apply (or a later apply after --fresh) refuses.
;; =============================================================================

(deftest spend-test
  (testing "spending marks the plan spent"
    (is (true? (:spent (sp/spend (plan-at "abc" nil))))))
  (testing "a spent plan is no longer valid, so a following apply refuses"
    (let [spent (sp/spend (plan-at "abc" nil))]
      (is (= :refuse (sp/plan-source {:fresh? false :stored-plan spent
                                      :manifest-identity "abc" :scope nil
                                      :now (+ t0 1000) :ttl-ms ttl-ms}))))))

;; =============================================================================
;; Spec: Manifest.identity — "hash identifying this manifest". It must change
;; iff a declarative input to plan assembly changes, and must NOT depend on the
;; live-queried world (installed packages, taps, target fs state — the TTL
;; covers that). The inputs are: manifest.edn, referenced cfg/*/manifest.edn,
;; secrets.edn, symlink-folder file listings, and slurped script bodies.
;; =============================================================================

(defn- inputs [& {:as m}]
  (merge {:manifest {:plan [:brew]}
          :modules {"cfg/brew/manifest.edn" {:pkg/brew {"htop" {}}}}
          :secrets {:gh-token "x"}
          :folder-listings {"~/.config/fish" ["config.fish"]}
          :script-bodies {"scripts/install.sh" "echo hi"}}
         m))

(deftest manifest-identity-stability-test
  (testing "identical inputs produce identical identity"
    (is (= (sp/manifest-identity' (inputs))
           (sp/manifest-identity' (inputs)))))
  (testing "identity is a stable hash string"
    (is (string? (sp/manifest-identity' (inputs))))))

(deftest manifest-identity-order-independence-test
  (testing "input ordering does not change the identity (canonicalised)"
    (is (= (sp/manifest-identity' (inputs :secrets {:a "1" :b "2"}))
           (sp/manifest-identity' (inputs :secrets {:b "2" :a "1"}))))))

(deftest manifest-identity-sensitivity-test
  (testing "editing the root manifest changes identity"
    (is (not= (sp/manifest-identity' (inputs))
              (sp/manifest-identity' (inputs :manifest {:plan [:brew :fish]})))))
  (testing "editing a referenced module manifest changes identity"
    (is (not= (sp/manifest-identity' (inputs))
              (sp/manifest-identity' (inputs :modules {"cfg/brew/manifest.edn"
                                                       {:pkg/brew {"htop" {} "jq" {}}}})))))
  (testing "changing a secret value changes identity"
    (is (not= (sp/manifest-identity' (inputs))
              (sp/manifest-identity' (inputs :secrets {:gh-token "y"})))))
  (testing "adding a file under a declared symlink folder changes identity"
    (is (not= (sp/manifest-identity' (inputs))
              (sp/manifest-identity' (inputs :folder-listings
                                             {"~/.config/fish" ["config.fish" "aliases.fish"]})))))
  (testing "editing a slurped script body changes identity"
    (is (not= (sp/manifest-identity' (inputs))
              (sp/manifest-identity' (inputs :script-bodies {"scripts/install.sh" "echo bye"}))))))
