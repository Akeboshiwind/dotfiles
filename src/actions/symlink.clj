(ns actions.symlink
  (:require [actions :as a]
            [clojure.java.io :as io]
            [babashka.fs :as fs]
            [display :as d]
            [outcome :as o]
            [utils :as u])
  (:import [java.nio.file Files]))

(defmethod a/requires :fs/symlink [_] nil)
(defmethod a/requires :fs/unlink [_] nil)

(defn- unlink-one [target-str expected-source]
  (let [target-file (io/file (u/expand-tilde target-str))
        target-path (.toPath target-file)]
    (cond
      (not (fs/exists? target-file {:nofollow-links true}))
      {:action [:fs/unlink target-str] :label target-str :status :skip :message "not found"}

      (not (Files/isSymbolicLink target-path))
      {:action [:fs/unlink target-str] :label target-str :status :error :message "not a symlink"}

      ;; Strict check - see note in link-one for lenient alternative
      (not= (Files/readSymbolicLink target-path)
            (.toPath (io/file expected-source)))
      {:action [:fs/unlink target-str] :label target-str :status :error :message "points elsewhere"}

      :else
      (do
        (fs/delete target-file)
        {:action [:fs/unlink target-str] :label target-str :status :ok :message "removed"}))))

(defn- check-link
  "Read-only check of symlink state. Returns :installed, :wrong, or :missing."
  [target-str source-str]
  (let [target (io/file (u/expand-tilde target-str))
        source (io/file source-str)
        target-path (.toPath target)]
    (cond
      (and (fs/exists? target {:nofollow-links true})
           (Files/isSymbolicLink target-path)
           (= (Files/readSymbolicLink target-path) (.toPath source)))
      :installed

      (fs/exists? target {:nofollow-links true})
      :wrong

      :else
      :missing)))

(defmethod a/check :fs/symlink [_ target-str source-str]
  (let [target (io/file (u/expand-tilde target-str))
        target-path (.toPath target)
        source (io/file source-str)]
    (cond
      (and (fs/exists? target {:nofollow-links true})
           (Files/isSymbolicLink target-path)
           (= (Files/readSymbolicLink target-path) (.toPath source)))
      o/satisfied

      (and (fs/exists? target {:nofollow-links true})
           (Files/isSymbolicLink target-path))
      (o/drift :wrong)

      (fs/exists? target {:nofollow-links true})
      (o/conflict "regular file exists at target")

      :else
      (o/drift :missing))))

(defmethod a/check :fs/unlink [_ target-str source-str]
  (let [target (io/file (u/expand-tilde target-str))
        target-path (.toPath target)]
    (cond
      (not (fs/exists? target {:nofollow-links true}))
      o/satisfied

      (not (Files/isSymbolicLink target-path))
      (o/conflict "not a symlink")

      (not= (Files/readSymbolicLink target-path)
            (.toPath (io/file source-str)))
      (o/conflict "points elsewhere")

      :else
      (o/drift :orphan))))

(defn- link-one [opts target-str source-str]
  (let [state (check-link target-str source-str)]
    (case state
      :installed
      {:action [:fs/symlink target-str] :label target-str :status :ok}

      :wrong
      {:action [:fs/symlink target-str] :label target-str :status :error :message "exists but wrong"}

      :missing
      (let [target (io/file (u/expand-tilde target-str))
            source (io/file source-str)]
        (when-let [parent (.getParentFile target)]
          (fs/create-dirs parent))
        (let [{:keys [exit]} (a/exec! opts ["ln" "-s" (.getAbsolutePath source) (.getAbsolutePath target)])]
          (if (zero? exit)
            {:action [:fs/symlink target-str] :label target-str :status :ok}
            {:action [:fs/symlink target-str] :label target-str :status :error}))))))

(defmethod a/status :fs/symlink [type items _ctx]
  (mapv (fn [[target source]]
          (let [state (check-link target source)]
            {:label target
             :action [type target]
             :state state
             :detail (when (= state :wrong) "wrong target")}))
        items))

(defmethod a/install! :fs/unlink [_ _opts items]
  (when (seq items)
    (d/section "Cleaning stale symlinks"
               (map (fn [[target source]] (unlink-one target source)) items))))

(defmethod a/install! :fs/symlink [_ opts items]
  (d/section "Creating symlinks"
             (map (fn [[target source]] (link-one opts target source)) items)))
