(ns actions.symlink
  (:require [actions.core :as a]
            [clojure.java.io :as io]
            [babashka.fs :as fs]
            [display :as d]
            [utils :as u])
  (:import [java.nio.file Files]))

(defn- unlink-one [target-str expected-source]
  (let [target-file (io/file (u/expand-tilde target-str))
        target-path (.toPath target-file)]
    (cond
      (not (fs/exists? target-file {:nofollow-links true}))
      {:label target-str :status :skip :message "not found"}

      (not (Files/isSymbolicLink target-path))
      {:label target-str :status :error :message "not a symlink"}

      (not= (Files/readSymbolicLink target-path)
            (.toPath (io/file expected-source)))
      {:label target-str :status :error :message "points elsewhere"}

      :else
      (do
        (fs/delete target-file)
        {:label target-str :status :ok :message "removed"}))))

(defn- link-one [target-str source-str]
  (let [target (io/file (u/expand-tilde target-str))
        source (io/file source-str)
        target-path (.toPath target)]
    (cond
      ;; Symlink exists and points to correct source
      (and (fs/exists? target {:nofollow-links true})
           (Files/isSymbolicLink target-path)
           (= (Files/readSymbolicLink target-path) (.toPath source)))
      {:label target-str :status :ok}

      ;; Something exists at target (file, dir, or wrong/broken symlink)
      (fs/exists? target {:nofollow-links true})
      {:label target-str :status :error :message "exists but wrong"}

      ;; Nothing exists, create symlink
      :else
      (do
        (when-let [parent (.getParentFile target)]
          (.mkdirs parent))
        (let [{:keys [exit]} (a/exec! ["ln" "-s" (.getAbsolutePath source) (.getAbsolutePath target)])]
          (if (zero? exit)
            {:label target-str :status :ok}
            {:label target-str :status :error}))))))

(defmethod a/install! :fs/unlink [_ items]
  (when (seq items)
    (d/section "Cleaning stale symlinks"
               (map (fn [[target source]] (unlink-one target source)) items))))

(defmethod a/install! :fs/symlink [_ items]
  (d/section "Creating symlinks"
             (map (fn [[target source]] (link-one target source)) items)))
