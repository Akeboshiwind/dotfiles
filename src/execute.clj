(ns execute
  (:require [actions.core :as a]
            ;; Load all action implementations
            [actions.script]
            [actions.brew]
            [actions.mise]
            [actions.mas]
            [actions.bbin]
            [actions.npm]
            [actions.claude]
            [actions.osx]
            [actions.symlink]))

(defn execute-plan
  "Execute plan in dependency order.
   Takes {:plan merged-map :order [[type key] ...]}
   Batches contiguous same-type actions for grouped output."
  [{:keys [plan order]}]
  (doseq [batch (partition-by first order)]
    (let [action-type (ffirst batch)
          data (into {} (map (fn [[_ k]] [k (get-in plan [action-type k])]) batch))]
      (if (a/supports? action-type)
        (a/install! action-type data)
        (println "Warning: Unknown action type:" action-type)))))
