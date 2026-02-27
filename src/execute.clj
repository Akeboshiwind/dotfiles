(ns execute
  (:require [actions :as a]
            [graph :as g]
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

(defn validate-plan
  "Validate all actions in plan. Returns seq of all errors, or nil if valid."
  [plan]
  (->> plan
       (mapcat (fn [[action-type items]] (a/validate action-type items)))
       (remove nil?)
       seq))

(defn- action-blocked-by
  "Return the failed/skipped action that blocks this action, or nil if not blocked."
  [{:keys [providers requires]} {:keys [failed skipped]} action]
  (let [all-blocked (into (or failed #{}) skipped)]
    (some (fn [req]
            (let [dep (if (keyword? req) (get providers req) req)]
              (when (contains? all-blocked dep) dep)))
          (get requires action))))

(defn- render-skips
  "Render skip results for blocked actions within a batch."
  [action-type blocked-actions state parsed]
  (doseq [[_ key] blocked-actions]
    (let [blocker (action-blocked-by parsed state [action-type key])]
      (d/render-result {:label (name key)
                        :status :skip
                        :message (str "skipped (dependency failed: " (subs (str (first blocker)) 1) "/" (name (second blocker)) ")")}))))

(defn- partition-with-deps
  "Partition order into batches of contiguous same-type actions,
   splitting at intra-type dependency boundaries so that an item
   never shares a batch with an item it depends on."
  [parsed order]
  (reduce
    (fn [{:keys [batches batch-set current-type]} action]
      (let [[type _] action
            intra-dep? (and (= type current-type)
                            (some (fn [req]
                                    (let [dep (if (keyword? req)
                                                (get (:providers parsed) req)
                                                req)]
                                      (contains? batch-set dep)))
                                  (get-in parsed [:requires action])))]
        (if (or (not= type current-type) intra-dep?)
          ;; New batch
          {:batches (conj batches [action])
           :batch-set #{action}
           :current-type type}
          ;; Extend current batch
          {:batches (update batches (dec (count batches)) conj action)
           :batch-set (conj batch-set action)
           :current-type current-type})))
    {:batches [] :batch-set #{} :current-type nil}
    order))

(defn- run-batch
  "Run a single batch: split blocked/runnable, execute, render skips.
   Returns updated state {:failed #{...} :skipped #{...}}."
  [plan parsed state batch dry-run]
  (let [action-type (ffirst batch)
        {blocked true runnable false}
        (group-by #(some? (action-blocked-by parsed state %)) batch)]
    (if-not (a/supports? action-type)
      (do (println "Warning: Unknown action type:" action-type) state)
      (let [run-data (into {} (map (fn [[_ k]] [k (get-in plan [action-type k])]) runnable))
            results (when (seq run-data)
                      (a/do-install! action-type {:dry-run dry-run} run-data))
            _ (when (seq blocked)
                (when-not (seq runnable) (println (subs (str action-type) 1)))
                (render-skips action-type blocked state parsed))
            newly-failed (->> results
                              (filter #(= :error (:status %)))
                              (map :action)
                              set)]
        (-> state
            (update :failed into newly-failed)
            (update :skipped into blocked))))))

(defn execute-plan
  "Execute plan in dependency order, skipping dependents of failed actions.
   Takes {:plan merged-map :order [[type key] ...] :dry-run bool}
   Batches contiguous same-type actions for grouped output.
   Returns {:failed #{...} :skipped #{...}}."
  [{:keys [plan order dry-run]}]
  (let [parsed (g/parse-plan plan)
        {:keys [batches]} (partition-with-deps parsed order)
        {:keys [failed skipped] :as result}
        (reduce
          (fn [state batch]
            (run-batch plan parsed state batch dry-run))
          {:failed #{} :skipped #{}}
          batches)]
    (when (or (seq failed) (seq skipped))
      (println)
      (println (str (d/red (str (count failed) " failed"))
                    ", "
                    (d/gray (str (count skipped) " skipped")))))
    result))
