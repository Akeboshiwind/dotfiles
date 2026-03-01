(ns execute
  (:require [actions :as a]
            [graph :as g]
            [display :as d]
            [outcome :as o]
            [registry]))

(defn- cancel-dependents!
  "Mark all dependents of `ref` as cancelled in the graph and cancelled set."
  [ag cancelled ref]
  (let [deps (g/dependents-of ag ref)]
    (swap! cancelled into deps)
    (reduce (fn [g dep]
              (assoc-in g [:nodes dep :check] o/cancelled))
            ag
            deps)))

(defn- flush-batch!
  "Execute accumulated actionable items as a single install! call.
   Returns updated graph with results applied and failures propagated."
  [ag cancelled type items]
  (if (empty? items)
    ag
    (let [results (a/do-install! type {} items)
          result-by-action (into {} (map (fn [r] [(:action r) r])) results)]
      (reduce (fn [g [key _]]
                (let [ref [type key]
                      result (get result-by-action ref)
                      failed? (= :error (:status result))
                      g (assoc-in g [:nodes ref :result] result)]
                  (if failed?
                    (-> g
                        (assoc-in [:nodes ref :check]
                                  (o/error (or (:message result) "install failed")))
                        (cancel-dependents! cancelled ref))
                    g)))
              ag
              items))))

(defn- render-skipped [ref check]
  (let [[_ key] ref]
    (d/render-result {:label (if (keyword? key) (name key) (str key))
                      :status :skip
                      :message (str "skipped (" (name (:outcome check)) ")")})))

(defn execute-plan
  "Execute an ActionGraph that has been through the check phase.
   Batches actionable nodes by type, calling install! once per batch.
   Flushes the batch when the type changes or a node depends on a cancelled item.
   Returns updated ActionGraph."
  [action-graph]
  (let [cancelled (atom #{})
        ;; Walk in topo order, accumulate per-type batches
        ag (loop [ag action-graph
                  remaining (:order action-graph)
                  current-type nil
                  batch {}]  ;; {key opts} accumulator
             (if (empty? remaining)
               ;; Flush final batch
               (flush-batch! ag cancelled current-type batch)
               (let [ref (first remaining)
                     [type key] ref
                     check (get-in ag [:nodes ref :check])
                     type-changed? (and current-type (not= type current-type))
                     now-cancelled? (contains? @cancelled ref)]
                 (cond
                   ;; Type changed — flush previous batch, then process this node
                   type-changed?
                   (let [ag (flush-batch! ag cancelled current-type batch)]
                     (recur ag remaining nil {}))

                   ;; Cancelled by a dependency
                   now-cancelled?
                   (let [ag (-> ag
                                (assoc-in [:nodes ref :check] o/cancelled)
                                (assoc-in [:nodes ref :result] {:status :skip}))]
                     (render-skipped ref o/cancelled)
                     (recur ag (rest remaining) type batch))

                   ;; Satisfied — skip
                   (o/satisfied? check)
                   (let [ag (assoc-in ag [:nodes ref :result] {:status :skip})]
                     (recur ag (rest remaining) type batch))

                   ;; Actionable — check if this node depends on anything in current batch
                   (o/actionable? check)
                   (let [reqs (get-in ag [:parsed :requires ref])
                         resolved (set (g/resolve-all-deps (:parsed ag) reqs))
                         batch-refs (set (map (fn [[k _]] [type k]) batch))
                         depends-on-batch? (some batch-refs resolved)]
                     (if depends-on-batch?
                       ;; Flush batch first, then re-process this node
                       (let [ag (flush-batch! ag cancelled current-type batch)]
                         (recur ag remaining type {}))
                       (recur ag (rest remaining) type
                              (assoc batch key (get-in ag [:nodes ref :opts])))))

                   ;; Blocking (error/conflict from check phase) — skip and propagate
                   :else
                   (let [ag (-> ag
                                (assoc-in [:nodes ref :result] {:status :skip})
                                (cancel-dependents! cancelled ref))]
                     (render-skipped ref check)
                     (recur ag (rest remaining) type batch))))))
        total-failed (->> (:nodes ag) vals
                          (filter #(= :error (:status (:result %)))) count)
        total-skipped (->> (:nodes ag) vals
                           (filter #(and (= :skip (:status (:result %)))
                                         (o/blocking? (:check %)))) count)]
    (when (or (pos? total-failed) (pos? total-skipped))
      (println)
      (println (str (d/red (str total-failed " failed"))
                    ", "
                    (d/gray (str total-skipped " skipped")))))
    ag))
