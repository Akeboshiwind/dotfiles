(ns status
  "Orchestrates --plan: shows what's installed, missing, outdated."
  (:require [actions :as a]
            [display :as d]
            [registry]))

(defn show-plan
  "Show the status of all actions in the plan.
   Groups consecutive same-type actions and renders their status."
  [{:keys [plan order]}]
  (let [batches (->> order
                     (partition-by first)
                     (map (fn [group]
                            (let [action-type (ffirst group)
                                  items (into {} (map (fn [[_ k]] [k (get-in plan [action-type k])]) group))]
                              [action-type items]))))
        actionable? #{:missing :outdated :wrong :orphan}
        all-results (mapcat (fn [[action-type items]]
                              (let [results (a/status action-type items nil)
                                    changes (filter #(actionable? (:state %)) results)]
                                (when (seq changes)
                                  (println (subs (str action-type) 1))
                                  (doseq [r changes]
                                    (d/render-plan-result r)))
                                results))
                            batches)
        freq (frequencies (map :state all-results))]
    (d/plan-summary freq)))
