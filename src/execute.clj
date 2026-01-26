(ns execute
  (:require [actions :as a]
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
            [actions.git]))

(defn validate-plan
  "Validate all actions in plan. Returns seq of all errors, or nil if valid."
  [plan]
  (->> plan
       (mapcat (fn [[action-type items]] (a/validate action-type items)))
       (remove nil?)
       seq))

(defn execute-plan
  "Execute plan in dependency order.
   Takes {:plan merged-map :order [[type key] ...] :dry-run bool}
   Batches contiguous same-type actions for grouped output."
  [{:keys [plan order dry-run]}]
  (doseq [batch (partition-by first order)]
    (let [action-type (ffirst batch)
          data (into {} (map (fn [[_ k]] [k (get-in plan [action-type k])]) batch))]
      (if (a/supports? action-type)
        (a/install! action-type {:dry-run dry-run} data)
        (println "Warning: Unknown action type:" action-type)))))
