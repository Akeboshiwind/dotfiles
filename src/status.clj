(ns status
  "Orchestrates --plan: shows what's installed, missing, outdated."
  (:require [display :as d]
            [outcome :as o]
            [registry]))

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
                             changes (remove #(= :installed (:state %)) results)]
                         (when (seq changes)
                           (println (subs (str action-type) 1))
                           (doseq [r changes]
                             (d/render-plan-result r)))
                         results))
                     batches)
        freq (frequencies (map :state all-states))]
    (d/plan-summary freq)))
