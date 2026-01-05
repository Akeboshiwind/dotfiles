(ns actions.symlink
  (:require [actions.core :as a]
            [clojure.java.io :as io]
            [babashka.fs :as fs]
            [utils :as u])
  (:import [java.nio.file Files Paths]))

(def ^:private GRAY "\033[90m")
(def ^:private GREEN "\033[32m")
(def ^:private RED "\033[31m")
(def ^:private RESET "\033[0m")

(defn- gray [s] (str GRAY s RESET))
(defn- green [s] (str GREEN s RESET))
(defn- red [s] (str RED s RESET))

(defmethod a/install! :fs/unlink [_ items _ctx]
  (when (seq items)
    (try
      (println " ┌─ Cleaning stale symlinks")
      (doseq [[target-str expected-source] items]
        (println " │ ┌─" target-str)
        (let [target-file (io/file (u/expand-tilde target-str))
              target-path (.toPath target-file)]
          (if-not (fs/exists? target-file {:nofollow-links true})
            (println " │ └─" (gray "skip (not found)"))
            (let [expected-source-path (.toPath (io/file expected-source))]
              (if-not (Files/isSymbolicLink target-path)
                (println " │ └─" (red "⚠ skip (not a symlink)"))
                (let [actual-link-target (Files/readSymbolicLink target-path)]
                  (if-not (= actual-link-target expected-source-path)
                    (println " │ └─" (red "⚠ skip (points elsewhere)"))
                    (do
                      (fs/delete target-file)
                      (println " │ └─" (green "✓ removed"))))))))))
      (catch Exception _
        (println " └─" (red "✗")))
      (println " └─" (green "✓")))))

(defmethod a/install! :fs/symlink [_ items {:keys [exec!]}]
  (try
    (println " ┌─ Creating Symlinks")
    (doseq [[target source] items]
      (println " │ ┌─" target)
      (let [target (io/file (u/expand-tilde target))
            source (io/file source)]
        (if (.exists target)
          (let [target-path (Paths/get (.toURI target))
                source-path (Paths/get (.toURI source))]
            (if (and (Files/isSymbolicLink target-path)
                     (= (Files/readSymbolicLink target-path)
                        source-path))
              (println " │ └─" (green "✓"))
              (println " │ └─" (red "✗"))))
          (do
            ;; Create parent directories if they don't exist
            (when-let [parent (.getParentFile target)]
              (.mkdirs parent))
            (let [cmd ["ln" "-s" (.getAbsolutePath source) (.getAbsolutePath target)]
                  {:keys [exit]} (exec! {:prefix " │ │"} cmd)]
              (println " │ └─" (if (zero? exit) (green "✓") (red "✗"))))))))
    (catch Exception _
      (println " └─" (red "✗")))
    (println " └─" (green "✓"))))
