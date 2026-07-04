(ns main
  (:require [actions :as a]
            [clojure.string :as str]
            [manifest :as m]
            [plan :as p]
            [execute :as e]
            [cache :as c]
            [graph :as g]
            [check :as chk]
            [status :as s]
            [stored-plan :as sp]))

(defn- format-graph-errors [errors]
  (let [{:keys [cycles missing duplicates]} errors]
    (str "Dependency graph errors:\n"
         (when (seq cycles)
           (str "  Cycles: " (pr-str cycles) "\n"))
         (when (seq missing)
           (str "  Missing providers: " (pr-str missing) "\n"))
         (when (seq duplicates)
           (str "  Duplicate providers: " (pr-str duplicates) "\n")))))

(defn- format-validation-errors [errors]
  (str "Validation errors:\n"
       (->> errors
            (map (fn [{:keys [action key error]}]
                   (str "  " (name action) " " (name key) ": " error)))
            (str/join "\n"))))

(defn- print-help []
  (println "Usage: syn [:<action>] [--apply] [--fresh]")
  (println "")
  (println "Options:")
  (println "  :<action>   Run only this action type (e.g., :pkg/brew, :fs/symlink)")
  (println "  --apply     Apply changes (default is plan-only)")
  (println "  --plan      Show what's installed, missing, and outdated (default)")
  (println "  --fresh     With --apply: ignore the stored plan and check live")
  (println "  --help      Show this help message")
  (println "")
  (println "Examples:")
  (println "  syn              Show status of all items (and store the plan)")
  (println "  syn --apply      Apply the stored plan (run `syn` first)")
  (println "  syn --apply --fresh  Check live and apply, ignoring any stored plan")
  (println "  syn :pkg/brew    Show status of brew packages")
  (println "  syn :pkg/brew --apply  Apply the stored plan for brew packages"))

(defn- parse-args
  "Parse CLI args. Returns {:action keyword-or-nil :plan-mode bool :apply-mode bool
   :fresh bool :help bool}"
  [args]
  (reduce (fn [acc arg]
            (cond
              (= arg "--help") (assoc acc :help true)
              (= arg "--plan") (assoc acc :plan-mode true)
              (= arg "--apply") (assoc acc :apply-mode true)
              (= arg "--fresh") (assoc acc :fresh true)
              (str/starts-with? arg ":") (assoc acc :action (keyword (subs arg 1)))
              :else acc))
          {:action nil :plan-mode false :apply-mode false :fresh false :help false}
          args))

(defn- filter-action-graph
  "Filter an ActionGraph to only include actions of the given type
   plus their transitive dependencies."
  [ag plan action]
  (let [filtered-order (g/filter-order plan (:order ag) action)
        needed (set filtered-order)]
    (-> ag
        (assoc :order filtered-order)
        (update :nodes select-keys needed))))

(defn- prepare-live
  "Build the plan, filter by scope, and run the live check phase. Returns
   {:checked ActionGraph :symlinks map :errors seq-or-nil}. Exits if a scoped
   run resolves to no actions. This is the expensive path — it queries package
   managers for orphans and for each action's live state."
  [entries cache action]
  (let [{:keys [plan symlinks errors]} (p/build! entries cache)
        ag (g/build-action-graph plan)
        ag (if action (filter-action-graph ag plan action) ag)]
    (when (and action (empty? (:order ag)))
      (println "No actions found for action" action)
      (System/exit 1))
    {:checked (chk/run-checks ag)
     :symlinks symlinks
     :errors (seq (concat (m/validate-secrets) errors))}))

(defn- save-after-apply!
  "Persist the cache after an apply: refresh symlink ownership from what the run
   observed, and spend the stored plan so it can never be replayed against the
   world this apply just changed (spec: SpendStoredPlanOnApply). Uses the live
   *cache* atom, which install! has updated with script records."
  [pre-cache executed symlinks]
  (c/save-cache!
    (-> @a/*cache*
        (assoc :symlinks (e/recordable-symlinks executed symlinks (get pre-cache :symlinks {})))
        (update :stored-plan #(when % (sp/spend %))))))

(defn- run-plan!
  "Plan mode: show the plan, then capture the checked plan to the cache so a
   following apply can replay it (spec: PersistCheckedPlan). Writes only the
   :stored-plan key — nothing else on the machine changes."
  [entries cache action identity]
  (let [{:keys [checked symlinks errors]} (prepare-live entries cache action)]
    (s/show-validation-errors errors)
    (s/show-plan checked)
    (c/save-cache!
      (assoc cache :stored-plan
             (sp/capture {:plan {:graph checked :symlinks symlinks :errors errors}
                          :manifest-identity identity
                          :scope action
                          :now (System/currentTimeMillis)})))))

(defn- run-fresh-apply!
  "Apply with --fresh: check live and apply, ignoring any stored plan (spec:
   Run.fresh). This is the classic behaviour, and the way to apply on a fresh
   checkout or after editing the manifest."
  [entries cache action]
  (let [{:keys [checked symlinks errors]} (prepare-live entries cache action)]
    (when errors
      (println (format-validation-errors errors))
      (System/exit 1))
    (println "Applying configurations...")
    (save-after-apply! cache (e/execute-plan checked) symlinks)))

(defn- run-replay-apply!
  "Apply by replaying a valid stored plan (spec: ReplayStoredPlan): execute the
   captured checked graph without re-assembling or re-checking. Validation
   errors captured at plan time still block the apply (spec: ApplyGate)."
  [cache]
  (let [{:keys [graph symlinks errors]} (:plan (:stored-plan cache))]
    (when (seq errors)
      (println (format-validation-errors errors))
      (System/exit 1))
    (println "Applying stored plan...")
    (save-after-apply! cache (e/execute-plan graph) symlinks)))

(defn- run-apply!
  "Route an apply to the fresh, replay or refuse path (spec: Run.fresh,
   ReplayStoredPlan, ApplyWithoutValidPlanAborts)."
  [entries cache action fresh]
  (if fresh
    (run-fresh-apply! entries cache action)
    (let [identity (sp/manifest-identity entries cache)
          source (sp/plan-source {:fresh? false
                                  :stored-plan (:stored-plan cache)
                                  :manifest-identity identity
                                  :scope action
                                  :now (System/currentTimeMillis)
                                  :ttl-ms sp/default-ttl-ms})]
      (case source
        :replay (run-replay-apply! cache)
        :refuse (do
                  (println (str "No valid plan for `syn"
                                (when action (str " " action))
                                " --apply`."))
                  (println (str "       Run `syn"
                                 (when action (str " " action))
                                 "` first to create a plan, or add --fresh to check live."))
                  (System/exit 1))))))

(defn -main
  "Main entry point for the dotfile manager.
   Loads manifest, then either shows-and-stores the plan (plan mode) or applies
   it — replaying a valid stored plan, or checking live under --fresh."
  [& args]
  (let [{:keys [action apply-mode fresh help]} (parse-args args)]
    (when help
      (print-help)
      (System/exit 0))
    (try
      (let [entries (m/load-manifest)
            cache (c/load-cache)
            _ (reset! a/*cache* cache)]
        (if apply-mode
          (run-apply! entries cache action fresh)
          (run-plan! entries cache action (sp/manifest-identity entries cache))))
      (catch clojure.lang.ExceptionInfo e
        (let [data (ex-data e)]
          (cond
            (or (:missing data) (:cycles data) (:duplicates data))
            (println (format-graph-errors data))

            (str/includes? (ex-message e) "Path escapes")
            (println "ERROR:" (ex-message e) "\n      " (pr-str data))

            (str/includes? (ex-message e) "Secret not found")
            (do
              (println "ERROR:" (ex-message e))
              (println "       Add it to secrets.edn (or set it to :secret/disabled)."))

            :else (throw e)))
        (System/exit 1))
      (catch Exception e
        (if (str/includes? (str (type e)) "EOF")
          (do
            (println "")
            (println "ERROR: Cache file is corrupt:" c/cache-file)
            (println "       Parse error:" (ex-message e))
            (println "       Delete the cache file and re-run.")
            (System/exit 1))
          (throw e))))))
