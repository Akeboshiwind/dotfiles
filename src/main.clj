(ns main
  (:require [clojure.string :as str]
            [manifest :as m]
            [optimise :as opt]
            [execute :as e]))

(defn- stage-from-args [args]
  (when-let [stage (first args)]
    (let [stage (if (str/starts-with? stage ":")
                  (subs stage 1)
                  stage)]
      (keyword stage))))

(defn- filter-steps [stage steps]
  (if stage
    (->> steps
         (map #(select-keys % [stage]))
         (remove empty?)
         vec)
    steps))

(defn -main [& args]
  (binding [e/*dry-run* false]
    (let [stage (stage-from-args args)
          {:keys [bootstrap config]} (m/load-manifest)
          bootstrap-steps (filter-steps stage [bootstrap])
          config-steps (->> config opt/optimize (filter-steps stage))]
      (when (and stage (empty? bootstrap-steps) (empty? config-steps))
        (println "No actions found for stage" stage)
        (System/exit 1))
      (when (seq bootstrap-steps)
        (println "Applying bootstrap configurations...")
        (e/execute-plan bootstrap-steps))
      (when (seq config-steps)
        (println "Applying main configurations...")
        (e/execute-plan config-steps)))))
