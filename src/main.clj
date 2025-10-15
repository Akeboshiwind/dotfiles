(ns main
  (:require [manifest :as m]
            [optimise :as opt]
            [execute :as e]))

(defn -main [& _]
  (binding [e/*dry-run* true]
    (let [{:keys [bootstrap config]} (m/load-manifest)]
      (println "Applying bootstrap configurations...")
      (e/execute-plan [bootstrap])
      (println "Applying main configurations...")
      (->> config opt/optimize e/execute-plan))))
