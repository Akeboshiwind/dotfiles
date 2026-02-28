(ns status
  "Orchestrates --plan: shows what's installed, missing, outdated."
  (:require [actions :as a]
            [actions.brew :as brew]
            [display :as d]
            ;; Load all action implementations
            [actions.script]
            [actions.mise]
            [actions.mas]
            [actions.bbin]
            [actions.npm]
            [actions.claude]
            [actions.osx]
            [actions.symlink]
            [actions.git]
            [actions.assert]))

(defn- build-ctx
  "Build a map of delays for expensive shared data.
   Each delay runs at most once, on first deref."
  []
  {:brew/formulae (delay (brew/installed-set :formula))
   :brew/casks    (delay (brew/installed-set :cask))
   :brew/outdated (delay (brew/outdated-map))
   :brew/services (delay (brew/services-map))})

(defn show-plan
  "Show the status of all actions in the plan.
   Groups consecutive same-type actions and renders their status."
  [{:keys [plan order]}]
  (let [ctx (build-ctx)
        batches (->> order
                     (partition-by first)
                     (map (fn [group]
                            (let [action-type (ffirst group)
                                  items (into {} (map (fn [[_ k]] [k (get-in plan [action-type k])]) group))]
                              [action-type items]))))
        actionable? #{:missing :outdated :wrong :orphan}
        all-results (mapcat (fn [[action-type items]]
                              (let [results (a/status action-type items ctx)
                                    changes (filter #(actionable? (:state %)) results)]
                                (when (seq changes)
                                  (println (subs (str action-type) 1))
                                  (doseq [r changes]
                                    (d/render-plan-result r)))
                                results))
                            batches)
        freq (frequencies (map :state all-results))]
    (d/plan-summary freq)))
