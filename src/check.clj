(ns check
  "Check phase: walks ActionGraph and runs a/check on each node."
  (:require [actions :as a]
            [graph :as g]))

(defn run-checks
  "Walk the ActionGraph, running a/check on each node.
   Stores CheckOutcome in :check field. Cancels dependents on blocking outcomes.
   Returns updated ActionGraph."
  [action-graph]
  (g/walk-graph action-graph
    (fn [_ag {:keys [ref opts] :as node}]
      (let [[type key] ref
            outcome (a/check type key opts)]
        (assoc node :check outcome)))))
