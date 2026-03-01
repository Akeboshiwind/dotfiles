(ns graph
  "Dependency graph for action ordering.

   Actions can declare:
   - :dep/provides #{:pkg/mise :pkg/mas} - enables these action types
   - :dep/requires #{[:action/type :specific-key]} - depends on specific actions

   Actions declare their own requirements via (a/requires type):
   - Returns nil for standalone actions (no dependencies)
   - Returns a capability keyword for actions that need a provider"
  (:require [weavejester.dependency :as dep]
            [actions :as a]))

(defn parse-plan
  "Parse plan into normalized dependency data. Returns:
   - :actions    - set of [type key] action references
   - :providers  - map of capability -> action that provides it
   - :requires   - map of action -> set of requirements (keywords or [type key] vectors)
   - :duplicates - seq of {:capability :providers} for duplicate providers"
  [plan]
  (let [actions (for [[type acts] plan, [key _] acts] [type key])

        provides (for [[type acts] plan, [key cfg] acts
                       :when (map? cfg), cap (:dep/provides cfg)]
                   [cap [type key]])
        by-cap (group-by first provides)

        requires (into {}
                       (for [[type acts] plan, [key cfg] acts
                             :let [action [type key]
                                   implicit (a/requires type)
                                   explicit (when (map? cfg) (:dep/requires cfg))
                                   reqs (cond-> #{} implicit (conj implicit) explicit (into explicit))]
                             :when (seq reqs)]
                         [action reqs]))]
    {:actions (set actions)
     :providers (->> by-cap
                     (map (fn [[cap [[_ action]]]] [cap action]))
                     (into {}))
     :requires requires
     :duplicates (for [[cap providers] by-cap :when (> (count providers) 1)]
                   {:capability cap :providers (mapv second providers)})}))

(defn- resolve-dep
  "Resolve a requirement to an action. Keywords lookup provider, vectors pass through."
  [providers req]
  (if (keyword? req)
    (get providers req)
    req))

(defn- find-missing
  "Find requirements with no provider."
  [{:keys [providers requires]}]
  (for [[action reqs] requires
        req reqs
        :when (keyword? req)
        :when (not (contains? providers req))]
    {:action action :missing-capability req}))

(defn- build-graph
  "Build dependency graph from parsed data."
  [{:keys [actions providers requires]}]
  (reduce
    (fn [g action]
      (let [deps (keep #(resolve-dep providers %) (get requires action))]
        (reduce #(dep/depend %1 action %2) g deps)))
    (dep/graph)
    actions))

(defn validate
  "Validate the plan's dependency graph.
   Returns nil if valid, or a map of errors:
   {:cycles [...] :missing [...] :duplicates [...]}"
  [plan]
  (let [{:keys [duplicates] :as parsed} (parse-plan plan)
        missing (seq (find-missing parsed))
        cycle-error (when-not (or (seq duplicates) missing)
                      (try
                        (build-graph parsed)
                        nil
                        (catch clojure.lang.ExceptionInfo e
                          (when (= :weavejester.dependency/circular-dependency
                                   (:reason (ex-data e)))
                            (select-keys (ex-data e) [:node :dependency])))))]
    (when (or missing (seq duplicates) cycle-error)
      (cond-> {}
        missing (assoc :missing (vec missing))
        (seq duplicates) (assoc :duplicates (vec duplicates))
        cycle-error (assoc :cycles [cycle-error])))))

(defn- action-comparator
  "Compare actions by [type key] for deterministic ordering."
  [[type-a key-a] [type-b key-b]]
  (let [type-cmp (compare (str type-a) (str type-b))]
    (if (zero? type-cmp)
      (compare (str key-a) (str key-b))
      type-cmp)))

(defn topological-sort
  "Return actions in valid execution order (dependencies first).
   Returns a vector of [action-type action-key] pairs.
   Order is deterministic: sorted by action type, then key."
  [plan]
  (let [{:keys [actions] :as parsed} (parse-plan plan)
        graph (build-graph parsed)
        sorted (dep/topo-sort action-comparator graph)
        orphans (sort action-comparator (remove (set sorted) actions))]
    (vec (concat orphans sorted))))

(defn transitive-deps
  "Given a plan and a set of target actions, return all actions needed
   (targets + their transitive dependencies) as a set."
  [plan targets]
  (let [{:keys [providers requires]} (parse-plan plan)]
    (loop [needed (set targets)
           queue (vec targets)]
      (if (empty? queue)
        needed
        (let [action (peek queue)
              deps (->> (get requires action)
                        (keep #(resolve-dep providers %))
                        (remove needed))]
          (recur (into needed deps)
                 (into (pop queue) deps)))))))

(defn filter-order
  "Filter execution order to only include actions of the given type,
   plus any actions they transitively depend on.
   Returns actions in dependency order (dependencies first)."
  [plan order action-type]
  (let [targets (filterv #(= action-type (first %)) order)
        needed (transitive-deps plan (set targets))]
    (filterv needed order)))

;; =============================================================================
;; ActionGraph
;; =============================================================================

(defn build-action-graph
  "Build an ActionGraph from a plan map.
   Validates the graph and returns:
   {:nodes    {[type key] {:ref [type key] :opts map :check nil :result nil}}
    :order    [[type key] ...]
    :parsed   <parse-plan output>}
   Throws on validation errors."
  [plan]
  (when-let [errors (validate plan)]
    (throw (ex-info "Dependency graph errors" errors)))
  (let [parsed (parse-plan plan)
        order (topological-sort plan)
        nodes (into {}
                    (map (fn [[type key :as ref]]
                           [ref {:ref ref
                                 :opts (get-in plan [type key])
                                 :check nil
                                 :result nil}]))
                    order)]
    {:nodes nodes
     :order order
     :parsed parsed}))

(defn- dependents-of
  "Return set of actions that directly or transitively depend on the given action."
  [{:keys [parsed order]} action]
  (let [{:keys [providers requires]} parsed]
    (loop [blocked #{action}
           result #{}
           remaining order]
      (if (empty? remaining)
        result
        (let [act (first remaining)
              deps (get requires act)
              resolved-deps (set (keep #(resolve-dep providers %) deps))
              is-blocked? (some blocked resolved-deps)]
          (if is-blocked?
            (recur (conj blocked act) (conj result act) (rest remaining))
            (recur blocked result (rest remaining))))))))

(defn walk-graph
  "Walk an ActionGraph in topological order, calling (visitor-fn graph node)
   for each node. visitor-fn returns an updated node map.
   If a node's :check is blocking?, downstream dependents are automatically cancelled.
   Returns updated ActionGraph."
  [action-graph visitor-fn]
  (let [cancelled (atom #{})]
    (reduce
      (fn [ag ref]
        (if (contains? @cancelled ref)
          (update-in ag [:nodes ref] assoc :check
                     {:outcome :cancelled})
          (let [node (get-in ag [:nodes ref])
                updated-node (visitor-fn ag node)
                check (:check updated-node)]
            (when (and check (#{:error :conflict :cancelled} (:outcome check)))
              (swap! cancelled into (dependents-of ag ref)))
            (assoc-in ag [:nodes ref] updated-node))))
      action-graph
      (:order action-graph))))
