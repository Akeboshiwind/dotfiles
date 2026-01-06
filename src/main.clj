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

(defn- print-help []
  (println "Usage: bootstrap [:<action>] [--dry-run]")
  (println "")
  (println "Options:")
  (println "  :<action>   Run only this action type (e.g., :pkg/brew, :fs/symlink)")
  (println "  --dry-run   Show what would be done without making changes")
  (println "  --help      Show this help message")
  (println "")
  (println "Examples:")
  (println "  bootstrap              Install everything")
  (println "  bootstrap :pkg/brew    Install only brew packages")
  (println "  bootstrap --dry-run    Preview all changes"))

(defn- parse-args
  "Parse CLI args. Returns {:action keyword-or-nil :dry-run bool :help bool}"
  [args]
  (reduce (fn [acc arg]
            (cond
              (= arg "--help") (assoc acc :help true)
              (= arg "--dry-run") (assoc acc :dry-run true)
              (str/starts-with? arg ":") (assoc acc :action (keyword (subs arg 1)))
              :else acc))
          {:action nil :dry-run false :help false}
          args))

(defn -main
  "Main entry point for the dotfile manager.
   Loads manifest, builds execution plan, validates dependencies, and executes actions.
   Supports --dry-run to preview changes and :<action> to filter by action type."
  [& args]
  (let [{:keys [action dry-run help]} (parse-args args)]
    (when help
      (print-help)
      (System/exit 0))
    (binding [a/*dry-run* dry-run]
      (try
        (let [entries (m/load-manifest)
              cache (c/load-cache)
              {:keys [plan order symlinks errors]} (p/build entries cache)
              filtered-order (if action
                               (g/filter-order plan order action)
                               order)]
          (when (and action (empty? filtered-order))
            (println "No actions found for action" action)
            (System/exit 1))
          (when-let [all-errors (seq (concat (m/validate-secrets)
                                             errors
                                             (e/validate-plan plan)))]
            (println (format-validation-errors all-errors))
            (System/exit 1))
          (println (if dry-run
                     "Dry run - showing what would be done..."
                     "Applying configurations..."))
          (e/execute-plan {:plan plan :order filtered-order})
          ;; Only update symlink cache if we processed symlinks (and not dry-run)
          (when (and (not dry-run)
                     (or (nil? action) (= action :fs/symlink)))
            (c/save-cache! (assoc cache :symlinks symlinks))))
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
            (throw e)))))))
