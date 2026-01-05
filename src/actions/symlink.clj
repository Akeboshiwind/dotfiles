(ns actions.symlink
  (:require [actions.core :as a]
            [clojure.java.io :as io]
            [babashka.fs :as fs]
            [display :as d]
            [utils :as u])
  (:import [java.nio.file Files Paths]))

(defmethod a/install! :fs/unlink [_ items _ctx]
  (when (seq items)
    (try
      (println " ┌─ Cleaning stale symlinks")
      (doseq [[target-str expected-source] items]
        (println " │ ┌─" target-str)
        (let [target-file (io/file (u/expand-tilde target-str))
              target-path (.toPath target-file)]
          (if-not (fs/exists? target-file {:nofollow-links true})
            (println " │ └─" (d/gray "skip (not found)"))
            (let [expected-source-path (.toPath (io/file expected-source))]
              (if-not (Files/isSymbolicLink target-path)
                (println " │ └─" (d/red "⚠ skip (not a symlink)"))
                (let [actual-link-target (Files/readSymbolicLink target-path)]
                  (if-not (= actual-link-target expected-source-path)
                    (println " │ └─" (d/red "⚠ skip (points elsewhere)"))
                    (do
                      (fs/delete target-file)
                      (println " │ └─" (d/green "✓ removed"))))))))))
      (catch Exception _
        (println " └─" (d/red "✗")))
      (println " └─" (d/green "✓")))))

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
              (println " │ └─" (d/green "✓"))
              (println " │ └─" (d/red "✗"))))
          (do
            ;; Create parent directories if they don't exist
            (when-let [parent (.getParentFile target)]
              (.mkdirs parent))
            (let [cmd ["ln" "-s" (.getAbsolutePath source) (.getAbsolutePath target)]
                  {:keys [exit]} (exec! {:prefix " │ │"} cmd)]
              (println " │ └─" (if (zero? exit) (d/green "✓") (d/red "✗"))))))))
    (catch Exception _
      (println " └─" (d/red "✗")))
    (println " └─" (d/green "✓"))))
