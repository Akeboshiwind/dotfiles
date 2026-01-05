(ns graph
  "Dependency graph for action ordering.

   Actions can declare:
   - :dep/provides #{:pkg/mise :pkg/mas} - enables these action types
   - :dep/requires #{[:action/type :specific-key]} - depends on specific actions

   Static no-dependency action types:
   - :pkg/script, :osx/defaults, :fs/symlink, :fs/unlink

   Implicit requirements (by action type):
   - All other action types implicitly require their type to be provided"
  (:require [weavejester.dependency :as dep]))

(def ^:private no-dep-actions
  #{:pkg/script :osx/defaults :fs/symlink :fs/unlink})

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
                                   implicit (when-not (no-dep-actions type) type)
                                   explicit (when (map? cfg) (:dep/requires cfg))
                                   reqs (cond-> #{} implicit (conj implicit) explicit (into explicit))]
                             :when (seq reqs)]
                         [action reqs]))]
    {:actions (set actions)
     :providers (into {} (map (juxt first (comp second first second))) by-cap)
     :requires requires
     :duplicates (for [[cap provs] by-cap :when (> (count provs) 1)]
                   {:capability cap :providers (mapv second provs)})}))

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
