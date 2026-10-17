(ns plan
  (:require [clojure.string :as str]
            [clojure.java.io :as io]
            [clojure.set :as set]
            [utils :as u]))

;; >> Resolve symlinks to root of repo

(defn- resolve-path! [base-dir path]
  (if (or (str/starts-with? path "/")    ; absolute
          (str/starts-with? path "~"))   ; home
    path
    ;; Relative path - resolve against base-dir
    (let [resolved (io/file base-dir path)
          canonical (.getCanonicalPath resolved)
          base-canonical (.getCanonicalPath (io/file base-dir))]
      (when-not (str/starts-with? canonical base-canonical)
        (throw (ex-info "Path escapes base directory"
                        {:path path
                         :resolved canonical
                         :base base-canonical})))
      canonical)))

(defn- resolve-paths-in-action! [step source-dir action]
  (if-let [symlinks (action step)]
    (->> symlinks
         (map (fn [[target source]] [target (resolve-path! source-dir source)]))
         (into {})
         (assoc step action))
    step))

(defn- resolve-symlink-paths! [entries]
  (mapv (fn [{:keys [source] :as entry}]
          (update entry :step #(-> %
                                   (resolve-paths-in-action! source :fs/symlink)
                                   (resolve-paths-in-action! source :fs/symlink-folder))))
        entries))

;; >> Breakdown :fs/symlink-folders into individual :fs/symlinks

(defn- list-files! [dir]
  (->> (file-seq dir)
       (filter #(.isFile %))))

(defn- relative-path [base-dir file]
  (let [base-path (.getPath base-dir)
        file-path (.getPath file)]
    (subs file-path (count base-path))))

(defn- create-symlink-mapping! [link-prefix content-dir]
  (let [base-dir (io/file (u/expand-tilde content-dir))
        files (list-files! base-dir)]
    (->> files
         (map (fn [file]
                (let [rel-path (relative-path base-dir file)]
                  [(str link-prefix rel-path)
                   (.getCanonicalPath file)])))
         (into {}))))

(defn- expand-symlink-folder! [step]
  (if-let [folder-symlinks (:fs/symlink-folder step)]
    (let [new-symlinks (->> folder-symlinks
                            (mapcat (fn [[s t]] (create-symlink-mapping! s t)))
                            (into {}))]
      (-> step
          (update :fs/symlink merge new-symlinks)
          (dissoc :fs/symlink-folder)))
    step))

(defn- expand-symlink-folders! [entries]
  (mapv #(update % :step expand-symlink-folder!) entries))

;; >> Validate and merge steps

(defn- source-label [{:keys [source plugin]}]
  (if plugin (str "plugin " (subs (str plugin) 1)) source))

(defn find-duplicate-keys
  "Find keys that appear in multiple entries within the same action type.
   Takes [{:step map :source string} ...]. Returns seq of error maps."
  [entries]
  (let [steps (map :step entries)
        action-types (->> steps (mapcat keys) distinct)]
    (for [action-type action-types
          :let [;; Collect [key source] pairs for this action type
                key-sources (->> entries
                                 (mapcat (fn [{:keys [step] :as entry}]
                                           (for [k (keys (get step action-type))]
                                             [k (source-label entry)])))
                                 (group-by first))
                ;; Find keys with multiple sources
                duplicates (->> key-sources
                                (filter (fn [[_ pairs]] (> (count pairs) 1))))]
          [k pairs] duplicates
          :let [sources (->> pairs (map second) distinct)]]
      {:action action-type
       :key k
       :sources sources
       :error (str "Defined in " (str/join ", " sources))})))

(defn- merge-steps
  "Merge all step maps into a single map, combining same action types"
  [entries]
  (apply merge-with merge {} (map :step entries)))

(defn- expand-exclusive
  "Turn the merged :syn/exclusive map {manager opts-or-false} into one node per
   manager that runs after all of that manager's installs. false opts a
   manager out."
  [merged]
  (let [declared (:syn/exclusive merged)
        nodes (into {}
                    (keep (fn [[manager opts]]
                            (cond
                              (false? opts) nil
                              (map? opts) [manager (assoc opts :dep/requires #{[:complete manager]})]
                              :else (throw (ex-info ":syn/exclusive values must be a map or false"
                                                    {:manager manager :value opts})))))
                    declared)]
    (if (seq nodes)
      (assoc merged :syn/exclusive nodes)
      (dissoc merged :syn/exclusive))))

(defn merge-layers
  "Merge plugin entries beneath the user's: a user declaration of a
   [type key] replaces a plugin's. Duplicates within a layer are errors.
   Returns {:merged plan-map :errors [...]}."
  [entries]
  (let [{plugin true user false} (group-by (comp some? :plugin) entries)]
    {:merged (expand-exclusive (merge-with merge (merge-steps plugin) (merge-steps user)))
     :errors (concat (find-duplicate-keys user) (find-duplicate-keys plugin))}))

;; >> Calculate stale symlinks to unlink

(defn calculate-unlinks
  "Compare plan's symlinks with cache, return stale symlinks to unlink.
   Returns {:unlinks {target source ...} :symlinks {target source ...}}"
  [cache plan]
  (let [current (:fs/symlink plan)
        cached (get cache :symlinks {})
        stale-keys (set/difference (set (keys cached))
                                   (set (keys current)))]
    {:unlinks (select-keys cached stale-keys)
     :symlinks current}))

;; >> Plan builder

(defn assemble
  "Cheap, declarative plan assembly — NO live package queries. Resolves source
   paths, expands symlink folders (a filesystem listing), merges module steps,
   and computes stale unlinks from the cache. Returns
   {:merged plan-map :symlinks {...} :unlinks {...} :errors [...]}.
   This is the part of a build that depends only on the repository and the
   cache, so it is safe to run on the fast apply path (e.g. to hash the
   manifest's identity)."
  [entries cache]
  (let [processed (->> entries
                       resolve-symlink-paths!
                       expand-symlink-folders!)
        {:keys [merged] duplicate-errors :errors} (merge-layers processed)
        {:keys [unlinks symlinks]} (calculate-unlinks cache merged)]
    {:merged merged
     :symlinks symlinks
     :unlinks unlinks
     :errors duplicate-errors}))

(defn build!
  "Build plan from entries. Takes [{:step map :source string} ...].
   Returns {:plan map :symlinks map :errors [...]}.
   Impure: reads the filesystem for path canonicalization and directory listing."
  [entries cache]
  (let [{:keys [merged symlinks unlinks errors]} (assemble entries cache)
        plan (cond-> merged
               (seq unlinks) (assoc :fs/unlink unlinks))]
    {:plan plan
     :symlinks symlinks
     :errors errors}))
