(ns main
  (:require [clojure.string :as str]
            [manifest :as m]
            [plan :as p]
            [execute :as e]
            [cache :as c]))

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
          {:keys [bootstrap plan]} (m/load-manifest)
          bootstrap-steps (filter-steps stage [bootstrap])
          built-plan (p/build plan)
          filtered-steps (filter-steps stage built-plan)
          ;; Only process symlinks when :fs/symlink is in the steps
          has-symlinks? (some :fs/symlink filtered-steps)
          cache (when has-symlinks? (c/load-cache))
          {:keys [steps symlinks]} (if has-symlinks?
                                     (p/inject-unlink cache filtered-steps)
                                     {:steps filtered-steps :symlinks nil})]
      (when (and stage (empty? bootstrap-steps) (empty? steps))
        (println "No actions found for stage" stage)
        (System/exit 1))
      (when (seq bootstrap-steps)
        (println "Applying bootstrap configurations...")
        (e/execute-plan bootstrap-steps))
      (when (seq steps)
        (println "Applying main configurations...")
        (e/execute-plan steps))
      (when has-symlinks?
        (c/save-cache! (assoc cache :symlinks symlinks))))))
