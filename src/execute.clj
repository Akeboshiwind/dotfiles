(ns execute
  (:require [actions :as a]
            [graph :as g]
            [display :as d]
            [outcome :as o]
            [registry]))

(defn- execute-node
  "Execute a single ActionGraph node. Returns updated node with :result."
  [node]
  (let [{:keys [ref opts check]} node
        [type key] ref]
    (cond
      ;; Already satisfied — skip
      (o/satisfied? check)
      (assoc node :result {:status :skip :message "already satisfied"})

      ;; Actionable — run install!
      (o/actionable? check)
      (let [results (a/do-install! type {} {key opts})
            result (first results)]
        (assoc node :result result))

      ;; Blocking (error/conflict/cancelled) — already handled by walk-graph
      :else
      (assoc node :result {:status :skip :message "blocked"}))))

(defn execute-plan
  "Execute an ActionGraph that has been through the check phase.
   Walks in topological order: skip satisfied, install! for drift/unknown,
   cancel downstream on failure. Returns updated ActionGraph."
  [action-graph]
  (let [failed (atom 0)
        skipped (atom 0)
        current-type (atom nil)
        ag (g/walk-graph action-graph
             (fn [_ag {:keys [ref check] :as node}]
               (let [[type key] ref]
                 (when (not= type @current-type)
                   (reset! current-type type)
                   (when (o/actionable? check)
                     ;; Type header printed by install!'s section
                     nil))
                 (cond
                   (o/satisfied? check)
                   (assoc node :result {:status :skip})

                   (o/actionable? check)
                   (let [results (a/do-install! type {} {key (:opts node)})
                         result (first results)
                         new-check (if (= :error (:status result))
                                     (o/error (or (:message result) "install failed"))
                                     check)]
                     (-> node
                         (assoc :result result)
                         (assoc :check new-check)))

                   ;; Cancelled/error/conflict — render skip
                   :else
                   (do
                     (when (not= type @current-type)
                       (println (subs (str type) 1)))
                     (d/render-result {:label (if (keyword? key) (name key) (str key))
                                       :status :skip
                                       :message (str "skipped (" (name (:outcome check)) ")")})
                     (swap! skipped inc)
                     (assoc node :result {:status :skip}))))))
        total-failed (->> (:nodes ag)
                          vals
                          (filter #(= :error (:status (:result %))))
                          count)
        total-skipped (->> (:nodes ag)
                           vals
                           (filter #(and (= :skip (:status (:result %)))
                                         (o/blocking? (:check %))))
                           count)]
    (when (or (pos? total-failed) (pos? total-skipped))
      (println)
      (println (str (d/red (str total-failed " failed"))
                    ", "
                    (d/gray (str total-skipped " skipped")))))
    ag))
