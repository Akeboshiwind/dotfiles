(ns facts
  "A facts snapshot is {query-key {:at millis :value v}}, with :error msg in
   place of :value when the query failed. The shell gathers it; checks only
   read it."
  (:require [actions :as a]
            [utils :as u]))

(defn value
  "The answer to query k. Throws if k was never gathered or its query failed."
  [facts k]
  (let [fact (get facts k)]
    (cond
      (nil? fact) (throw (ex-info (str "no fact for query " (pr-str k)) {:query k}))
      (contains? fact :error) (throw (ex-info (:error fact) {:query k}))
      :else (:value fact))))

(defn- ask [k]
  (let [at (System/currentTimeMillis)]
    (try {:at at :value (a/run-query k)}
         (catch Exception e {:at at :error (or (ex-message e) (str e))}))))

(defn gather
  "Return facts extended with an answer to each query it doesn't already hold.
   Each query runs once. A failing query is recorded, not thrown."
  [facts queries]
  (reduce (fn [acc k] (assoc acc k (ask k)))
          facts
          (remove #(contains? facts %) queries)))

(defmethod a/run-query :command [[_ cmd]]
  (u/command-exists? cmd))
