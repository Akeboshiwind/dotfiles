(ns status
  "Orchestrates --plan: shows what's installed, missing, outdated."
  (:require [clojure.string :as str]
            [display :as d]
            [outcome :as o]
            [registry]))

(defn- fmt-duration
  "Human duration for the status banner, e.g. 45s, 3m, 3m 20s."
  [ms]
  (let [s (quot (max 0 ms) 1000)
        m (quot s 60)
        rem (mod s 60)]
    (if (< s 60)
      (str s "s")
      (str m "m" (when (pos? rem) (str " " rem "s"))))))

(defn- scope-label [scope]
  (if scope (subs (str scope) 1) "all actions"))

(defn show-stored-status
  "Print the status banner for the stored plan (spec: surface StoredPlanReport).
   Takes the classification map from stored-plan/status. Reports each condition
   that holds — spent/expired/stale can co-occur — plus age and captured scope.
   Staleness is tri-state: when it is :unknown (the current manifest would not
   assemble) the banner says so and surfaces manifest-error — how it is broken."
  [{:keys [replayable spent expired stale age-ms scope]} ttl-ms manifest-error]
  (if replayable
    (println (d/green "✓ stored plan replayable")
             (d/gray (str "· captured " (fmt-duration age-ms) " ago"
                          " · expires in " (fmt-duration (- ttl-ms age-ms))
                          " · scope: " (scope-label scope))))
    (let [reasons (cond-> []
                    spent              (conj "already applied")
                    expired            (conj "expired")
                    (true? stale)      (conj "manifest changed")
                    (= :unknown stale) (conj (str "manifest won't load: " manifest-error)))]
      (println (d/yellow (str "⚠ stored plan not replayable (" (str/join ", " reasons) ")"))
               (d/gray (str "· captured " (fmt-duration age-ms) " ago"
                            " · scope: " (scope-label scope))))
      (println (d/gray "  run `syn` for a fresh plan, or `syn --apply --fresh` to check live")))))

(defn- outcome->state
  "Map a CheckOutcome to a legacy display state keyword."
  [{:keys [outcome kind]}]
  (case outcome
    :satisfied :installed
    :drift kind
    :unknown :unknown
    :conflict :wrong
    :error :error
    :cancelled :cancelled))

(defn show-validation-errors
  "Print validation errors that would block an apply. No-op when nil/empty."
  [errors]
  (when (seq errors)
    (println (d/red "Validation errors (--apply will be blocked):"))
    (doseq [{:keys [action key error]} errors]
      (println (str "  " (name action) " "
                    (if (keyword? key) (name key) (str key))
                    ": " error)))
    (println)))

(defn show-plan
  "Show the status of all actions in the ActionGraph.
   Displays everything except satisfied (installed) items, grouped by type."
  [action-graph]
  (let [nodes (:nodes action-graph)
        batches (->> (:order action-graph)
                     (partition-by first)
                     (map (fn [group]
                            [(ffirst group)
                             (map #(get nodes %) group)])))
        all-states (mapcat
                     (fn [[action-type node-group]]
                       (let [results (map (fn [{:keys [ref check]}]
                                            (let [[_ key] ref
                                                  state (outcome->state check)]
                                              {:label (if (keyword? key) (name key) (str key))
                                               :state state
                                               :action ref
                                               :detail (when (:message check)
                                                         (:message check))
                                               :instructions (:detail check)}))
                                          node-group)
                             ;; Show everything unsatisfied, plus satisfied items
                             ;; that carry a warning message
                             changes (remove #(and (= :installed (:state %))
                                                   (nil? (:detail %)))
                                             results)]
                         (when (seq changes)
                           (println (subs (str action-type) 1))
                           (doseq [r changes]
                             (d/render-plan-result r)))
                         results))
                     batches)
        freq (frequencies (map :state all-states))]
    (d/plan-summary freq)))
