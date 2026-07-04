(ns stored-plan
  "Persisted-plan logic: a plan-mode run captures its checked plan so a
   following apply can replay it without re-running the live check phase.
   Pure decision cores; persistence mechanics live in cache.clj."
  (:require [cache :as c]
            [clojure.java.io :as io]
            [manifest :as m]
            [plan :as p]))

(def default-ttl-ms
  "Default plan time-to-live (spec: config.plan_ttl = 5.minutes)."
  (* 5 60 1000))

(defn valid?
  "Is a captured plan valid to replay for the current invocation?
   Four AND-conditions (spec: StoredPlan.valid_for + TTL): the plan is unspent,
   was built from the same manifest, was captured under the same scope, and is
   still within the TTL window. `now` and `:captured-at` are epoch-millis."
  [stored-plan {:keys [manifest-identity scope now ttl-ms]}]
  (boolean
    (and stored-plan
         (not (:spent stored-plan))
         (= (:manifest-identity stored-plan) manifest-identity)
         (= (:scope stored-plan) scope)
         (<= (- now (:captured-at stored-plan)) ttl-ms))))

(defn plan-source
  "Decide how an apply run obtains its plan.
   :fresh  — ignore any stored plan and check live (spec: Run.fresh / --fresh)
   :replay — a valid stored plan exists, execute it (spec: ReplayStoredPlan)
   :refuse — no valid stored plan; abort (spec: ApplyWithoutValidPlanAborts)"
  [{:keys [fresh? stored-plan] :as ctx}]
  (cond
    fresh?                    :fresh
    (valid? stored-plan ctx)  :replay
    :else                     :refuse))

(defn capture
  "Build a StoredPlan record from a checked plan (spec: PersistCheckedPlan).
   Tagged with the manifest identity and scope in force; starts unspent,
   stamped with the capture instant `now` (epoch-millis)."
  [{:keys [plan manifest-identity scope now]}]
  {:manifest-identity manifest-identity
   :scope scope
   :spent false
   :captured-at now
   :plan plan})

(defn spend
  "Mark a stored plan spent (spec: SpendStoredPlanOnApply). A completed apply
   consumes the plan so it can never be replayed against the world it changed."
  [stored-plan]
  (assoc stored-plan :spent true))

(defn- canonical
  "A stable, order-independent rendering of nested data. Maps become vectors of
   [k v] pairs sorted by the printed key (robust to mixed keyword/string keys,
   as real manifests have); sets are sorted; sequence order is preserved."
  [x]
  (cond
    (map? x)        (->> x
                         (map (fn [[k v]] [(canonical k) (canonical v)]))
                         (sort-by (comp pr-str first))
                         vec)
    (set? x)        (->> x (map canonical) (sort-by pr-str) vec)
    (sequential? x) (mapv canonical x)
    :else           x))

(defn manifest-identity'
  "Pure: hash the declarative inputs that determine the assembled plan (spec:
   Manifest.identity). Sensitive to every input the operator controls by
   editing the repo — the root manifest, referenced module manifests, secrets,
   the file listings of declared symlink folders, and slurped script bodies —
   and independent of input ordering. Deliberately excludes the live-queried
   world (installed packages, taps, target filesystem state); staleness there
   is bounded by the TTL, not the identity."
  [inputs]
  (c/content-hash (pr-str (canonical inputs))))

(defn- script-bodies
  "Slurp the contents of every :path-referenced file in the assembled plan (a
   script action's body lives in a file, not the manifest). Editing such a file
   must invalidate a captured plan, so its content joins the identity."
  [merged]
  (into {}
        (for [[_type acts] merged
              [_key opts] acts
              :when (and (map? opts) (:path opts))
              :let [path (:path opts)
                    f (io/file path)]
              :when (.isFile f)]
          [path (slurp f)])))

(defn manifest-identity
  "Collect the declarative inputs and hash them (spec: Manifest.identity).
   Impure: reads the manifest and modules (via the cheap plan assembly, which
   also folder-expands symlinks so a new file under a declared folder counts),
   the secrets, and any slurped script bodies. Deliberately excludes the
   live-queried world (installed packages, taps, target filesystem state);
   drift there is bounded by the TTL, not the identity."
  [entries cache]
  (let [{:keys [merged]} (p/assemble entries cache)]
    (manifest-identity'
      {:plan merged
       :secrets (m/all-secrets)
       :scripts (script-bodies merged)})))
