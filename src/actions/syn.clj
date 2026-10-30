(ns actions.syn
  "Exclusive managers: a manager declared exclusive has one :syn/exclusive node
   whose drift is :extra, whatever it has installed that the manifest doesn't
   declare."
  (:require [actions :as a]
            [display :as d]
            [facts :as f]
            [manifest :as m]
            [outcome :as o]
            [plan :as p]
            [stored-plan :as sp]))

(defmethod a/requires :syn/exclusive [_] nil)

(defmethod a/label :syn/exclusive [_ manager _opts] (subs (str manager) 1))

(defn- declared-set
  []
  (let [entries (m/load-manifest)
        cache @a/*cache*
        merged (:merged (p/assemble entries cache))
        by-name (into {}
                      (for [[type items] (dissoc merged :syn/exclusive)]
                        [type (into {} (map (fn [[k opts]] [(if (keyword? k) (name k) (str k)) opts])) items)]))]
    {:root (m/root)
     :id (sp/manifest-identity entries cache)
     :entries by-name
     :types (update-vals by-name (comp set keys))}))

(defmethod a/run-query :manifest [[_ what]]
  (case what :declared (declared-set)))

(defmethod a/run-query :syn [[_ what]]
  (case what :pinned-root (:pinned-root @a/*cache*)))

(def ^:private base-queries #{[:manifest :declared] [:syn :pinned-root]})

(defmethod a/queries :syn/exclusive [_ declared]
  (into base-queries (mapcat (comp a/extras-queries key)) declared))

(defmethod a/check :syn/exclusive [_ manager _opts facts]
  (let [{:keys [root types]} (f/value facts [:manifest :declared])
        pinned (f/value facts [:syn :pinned-root])
        source {:root root :at (get-in facts [[:manifest :declared] :at])}
        outcome (cond
                  (nil? pinned)
                  (o/conflict "root not pinned yet; a successful apply pins it")

                  (not= pinned root)
                  (o/conflict (str "declared set read from " root ", not the pinned root " pinned))

                  :else
                  (let [extras (a/extras manager (get types manager #{}) facts)]
                    (if (seq extras)
                      (assoc (o/drift :extra) :extras extras)
                      o/satisfied)))]
    (assoc outcome :source source)))

(defmethod a/install-queries :syn/exclusive [_ items]
  (into base-queries
        (mapcat (fn [[manager _]] (into (a/extras-queries manager) (a/removal-queries manager))))
        items))

(defn- label [manager] (subs (str manager) 1))

(defn removable
  "The extras an apply may remove: those the plan showed that are still extra
   on facts gathered for this apply. Pure."
  [shown fresh]
  (let [shown-names (set (map :name shown))]
    (filterv #(contains? shown-names (:name %)) fresh)))

(defn- remove-from [type manager opts facts]
  (let [ref [type manager]
        fresh (a/check type manager opts facts)
        shown (:extras (f/value facts [:plan :check ref]))
        to-remove (removable shown (:extras fresh))
        skip (fn [msg] [{:action ref :label (label manager) :status :skip :message msg}])]
    (cond
      (not (o/drift? fresh)) (skip (or (:message fresh) "no extras left"))
      (empty? to-remove) (skip "none of the extras the plan showed are left")
      :else
      (let [results (a/remove-extras! manager {} to-remove facts)
            failed (count (filter #(= :error (:status %)) results))]
        [{:action ref
          :label (label manager)
          :status (if (pos? failed) :error :ok)
          :message (if (pos? failed) (str failed " failed") (str "removed " (count to-remove)))}]))))

(defmethod a/install! :syn/exclusive [type _opts items facts]
  (d/section "Removing undeclared packages"
             (mapcat (fn [[manager opts]] (remove-from type manager opts facts)) items)))
