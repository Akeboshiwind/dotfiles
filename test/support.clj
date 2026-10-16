(ns support
  (:require [actions :as a]
            [check :as chk]
            [facts :as f]
            [plan :as p]
            [registry]))

(defn facts-of
  "A facts snapshot from {query-key value}."
  [m]
  (into {} (map (fn [[k v]] [k {:at 0 :value v}])) m))

(defn check-live
  "Gather what one item's check reads, then check it. For tmp-dir fixtures."
  [type key opts]
  (a/check type key opts (f/gather {} (a/queries type {key opts}))))

(defn run-checks-live
  "Gather what an ActionGraph's checks read, then run them. For tmp-dir fixtures."
  [ag]
  (chk/run-checks ag (f/gather {} (chk/queries ag))))

(defn orphans-live
  [plan]
  (let [types (p/orphan-types-for nil)]
    (p/calculate-orphans plan types (f/gather {} (p/orphan-queries plan types)))))
