(ns main
  (:require [clojure.string :as str]
            [manifest :as m]
            [plan :as p]
            [execute :as e]
            [cache :as c]
            [graph :as g]
            [actions :as a]))

(defn- format-graph-errors [errors]
  (let [{:keys [cycles missing duplicates]} errors]
    (str "Dependency graph errors:\n"
         (when (seq cycles)
           (str "  Cycles: " (pr-str cycles) "\n"))
         (when (seq missing)
           (str "  Missing providers: " (pr-str missing) "\n"))
         (when (seq duplicates)
           (str "  Duplicate providers: " (pr-str duplicates) "\n")))))

(defn- format-validation-errors [errors]
  (str "Validation errors:\n"
       (->> errors
            (map (fn [{:keys [action key error]}]
                   (str "  " (name action) " " (name key) ": " error)))
            (str/join "\n"))))

(defn- parse-stage [args]
  (when-let [stage (first args)]
    (let [stage (if (str/starts-with? stage ":")
                  (subs stage 1)
                  stage)]
      (keyword stage))))

(defn -main [& args]
  (binding [a/*dry-run* false]
    (try
      (let [stage (parse-stage args)
            entries (m/load-manifest)
            cache (c/load-cache)
            {:keys [plan order symlinks]} (p/build entries cache)
            filtered-order (if stage
                             (g/filter-order plan order stage)
                             order)]
        (when (and stage (empty? filtered-order))
          (println "No actions found for stage" stage)
          (System/exit 1))
        (when-let [errors (seq (concat (m/validate-secrets)
                                       (e/validate-plan plan)))]
          (println (format-validation-errors errors))
          (System/exit 1))
        (println "Applying configurations...")
        (e/execute-plan {:plan plan :order filtered-order})
        ;; Only update symlink cache if we processed symlinks
        (when (or (nil? stage) (= stage :fs/symlink))
          (c/save-cache! (assoc cache :symlinks symlinks))))
      (catch clojure.lang.ExceptionInfo e
        (let [data (ex-data e)]
          (cond
            (:missing data)
            (println (format-graph-errors data))

            (str/includes? (ex-message e) "Path escapes")
            (println "ERROR:" (ex-message e) "\n      " (pr-str data))

            :else (throw e)))
        (System/exit 1))
      (catch Exception e
        (if (str/includes? (str (type e)) "EOF")
          (do
            (println "")
            (println "ERROR: Cache file is corrupt:" c/cache-file)
            (println "       Parse error:" (ex-message e))
            (println "       Delete the cache file and re-run.")
            (System/exit 1))
          (throw e))))))
