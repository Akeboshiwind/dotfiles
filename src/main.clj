(ns main
  (:require [clojure.string :as str]
            [manifest :as m]
            [plan :as p]
            [execute :as e]
            [cache :as c]
            [graph :as g]
            [check :as chk]
            [status :as s]))

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

(defn- print-help []
  (println "Usage: bootstrap [:<action>] [--plan]")
  (println "")
  (println "Options:")
  (println "  :<action>   Run only this action type (e.g., :pkg/brew, :fs/symlink)")
  (println "  --plan      Show what's installed, missing, and outdated")
  (println "  --help      Show this help message")
  (println "")
  (println "Examples:")
  (println "  bootstrap              Install everything")
  (println "  bootstrap :pkg/brew    Install only brew packages")
  (println "  bootstrap --plan       Show status of all items"))

(defn- parse-args
  "Parse CLI args. Returns {:action keyword-or-nil :plan-mode bool :help bool}"
  [args]
  (reduce (fn [acc arg]
            (cond
              (= arg "--help") (assoc acc :help true)
              (= arg "--plan") (assoc acc :plan-mode true)
              (str/starts-with? arg ":") (assoc acc :action (keyword (subs arg 1)))
              :else acc))
          {:action nil :plan-mode false :help false}
          args))

(defn- filter-action-graph
  "Filter an ActionGraph to only include actions of the given type
   plus their transitive dependencies."
  [ag plan action]
  (let [filtered-order (g/filter-order plan (:order ag) action)
        needed (set filtered-order)]
    (-> ag
        (assoc :order filtered-order)
        (update :nodes select-keys needed))))

(defn -main
  "Main entry point for the dotfile manager.
   Loads manifest, builds ActionGraph, runs check phase, then executes or displays."
  [& args]
  (let [{:keys [action plan-mode help]} (parse-args args)]
    (when help
      (print-help)
      (System/exit 0))
    (try
      (let [entries (m/load-manifest)
            cache (c/load-cache)
            {:keys [plan order symlinks errors]} (p/build! entries cache)
            ag (g/build-action-graph plan)
            ag (if action (filter-action-graph ag plan action) ag)]
        (when (and action (empty? (:order ag)))
          (println "No actions found for action" action)
          (System/exit 1))
        (let [checked (chk/run-checks ag)]
          (if plan-mode
            (s/show-plan checked)
            (do
              (when-let [all-errors (seq (concat (m/validate-secrets)
                                                  errors
                                                  (e/validate-plan plan)))]
                (println (format-validation-errors all-errors))
                (System/exit 1))
              (println "Applying configurations...")
              (e/execute-plan checked)
              (c/save-cache! (assoc cache :symlinks symlinks))))))
      (catch clojure.lang.ExceptionInfo e
        (let [data (ex-data e)]
          (cond
            (or (:missing data) (:cycles data) (:duplicates data))
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
