(ns main
  (:require [clojure.string :as str]
            [manifest :as m]
            [plan :as p]
            [execute :as e]
            [cache :as c]
            [graph :as g]))

(defn- format-errors [errors]
  (let [{:keys [cycles missing duplicates]} errors]
    (str "Dependency graph errors:\n"
         (when (seq cycles)
           (str "  Cycles: " (pr-str cycles) "\n"))
         (when (seq missing)
           (str "  Missing providers: " (pr-str missing) "\n"))
         (when (seq duplicates)
           (str "  Duplicate providers: " (pr-str duplicates) "\n")))))

(defn- parse-stage [args]
  (when-let [stage (first args)]
    (let [stage (if (str/starts-with? stage ":")
                  (subs stage 1)
                  stage)]
      (keyword stage))))

(defn -main [& args]
  (binding [e/*dry-run* false]
    (try
      (let [stage (parse-stage args)
            steps (m/load-manifest)
            cache (c/load-cache)
            {:keys [plan order symlinks]} (p/build steps cache)
            filtered-order (if stage
                             (g/filter-order plan order stage)
                             order)]
        (when (and stage (empty? filtered-order))
          (println "No actions found for stage" stage)
          (System/exit 1))
        (println "Applying configurations...")
        (e/execute-plan {:plan plan :order filtered-order})
        ;; Only update symlink cache if we processed symlinks
        (when (or (nil? stage) (= stage :fs/symlink))
          (c/save-cache! (assoc cache :symlinks symlinks))))
      (catch clojure.lang.ExceptionInfo e
        (if (:missing (ex-data e))
          (do
            (println (format-errors (ex-data e)))
            (System/exit 1))
          (throw e))))))
