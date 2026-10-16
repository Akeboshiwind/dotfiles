(ns check
  "Check phase: walks ActionGraph and runs a/check on each node."
  (:require [actions :as a]
            [graph :as g]))

(defn queries
  "The set of query keys the checks of an ActionGraph's nodes read. Pure."
  [action-graph]
  (->> (keys (:nodes action-graph))
       (group-by first)
       (into #{} (mapcat (fn [[type refs]]
                           (a/queries type (into {} (map (fn [[_ key :as ref]]
                                                           [key (get-in action-graph [:nodes ref :opts])]))
                                                 refs)))))))

(defn run-checks
  "Walk the ActionGraph, running a/check on each node against facts.
   Stores CheckOutcome in :check field. Cancels dependents on blocking outcomes.
   Returns updated ActionGraph."
  [action-graph facts]
  (g/walk-graph action-graph
    (fn [_ag {:keys [ref opts] :as node}]
      (let [[type key] ref
            outcome (a/check type key opts facts)]
        (assoc node :check outcome)))))
