(ns status
  "Orchestrates --plan: shows what's installed, missing, outdated."
  (:require [actions :as a]
            [display :as d]
            ;; Load all action implementations
            [actions.script]
            [actions.brew]
            [actions.mise]
            [actions.mas]
            [actions.bbin]
            [actions.npm]
            [actions.claude]
            [actions.osx]
            [actions.symlink]
            [actions.git]
            [actions.assert]))

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
        all-results (mapcat (fn [[action-type items]]
                              (println (subs (str action-type) 1))
                              (let [results (a/status action-type items)]
                                (doseq [r results]
                                  (d/render-plan-result r))
                                results))
                            batches)
        freq (frequencies (map :state all-results))]
    (d/plan-summary freq)))
