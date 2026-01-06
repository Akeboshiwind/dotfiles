(ns plan
  (:require [clojure.string :as str]
            [clojure.java.io :as io]
            [clojure.set :as set]
            [graph :as g]
            [utils :as u]))


;; >> Resolve symlinks to root of repo

(defn- resolve-path [base-dir path]
  (if (str/starts-with? path "./")
    (let [resolved (str base-dir "/" (subs path 2))
          canonical (.getCanonicalPath (io/file resolved))
          base-canonical (.getCanonicalPath (io/file base-dir))]
      (when-not (str/starts-with? canonical base-canonical)
        (throw (ex-info "Path escapes base directory"
                        {:path path
                         :resolved canonical
                         :base base-canonical})))
      canonical)
    path))

(defn- resolve-paths-in-step [action {{:keys [source-dir]} :context :as step}]
  (if-let [symlinks (action step)]
    (->> symlinks
         (map (fn [[target source]] [target (resolve-path source-dir source)]))
         (into {})
         (assoc step action))
    step))

(defn- resolve-symlink-paths [steps]
  (->> steps
       (mapv (partial resolve-paths-in-step :fs/symlink))
       (mapv (partial resolve-paths-in-step :fs/symlink-folder))))


;; >> Breakdown :fs/symlink-folders into individual :fs/symlinks

(defn- list-files [dir-path]
  (let [dir (io/file (u/expand-tilde dir-path))]
    (->> (file-seq dir)
         (filter #(.isFile %)))))

(defn- relative-path [base-dir file]
  (let [base-path (.getPath base-dir)
        file-path (.getPath file)]
    (subs file-path (count base-path))))

(defn- create-symlink-mapping [source-dir target-dir]
  (let [base-dir (io/file (u/expand-tilde target-dir))
        files (list-files target-dir)]
    (->> files
         (map (fn [file]
                (let [rel-path (relative-path base-dir file)]
                  [(str source-dir rel-path)
                   (str target-dir rel-path)])))
         (into {}))))

(defn- expand-symlink-folder [step]
  (if-let [folder-symlinks (:fs/symlink-folder step)]
    (let [new-symlinks (->> folder-symlinks
                            (mapcat (fn [[s t]] (create-symlink-mapping s t)))
                            (into {}))]
      (-> step
          (update :fs/symlink merge new-symlinks)
          (dissoc :fs/symlink-folder)))
    step))

(defn- expand-symlink-folders [steps]
  (mapv expand-symlink-folder steps))


;; >> Drop context key (no longer needed)

(defn- drop-context [steps]
  (mapv #(dissoc % :context) steps))


;; >> Merge all steps into a single map

(defn- merge-steps
  "Merge all step maps into a single map, combining same action types"
  [steps]
  (apply merge-with merge steps))


;; >> Calculate stale symlinks to unlink

(defn- calculate-unlinks
  "Compare plan's symlinks with cache, return stale symlinks to unlink"
  [cache plan]
  (let [current (->> (:fs/symlink plan)
                     (map (fn [[target source]]
                            [target (.getAbsolutePath (io/file source))]))
                     (into {}))
        cached (get cache :symlinks {})
        stale-keys (set/difference (set (keys cached))
                                   (set (keys current)))]
    {:unlinks (select-keys cached stale-keys)
     :symlinks current}))


;; >> Plan builder

(defn build
  "Build plan from steps. Returns {:plan map :order [[type key] ...] :symlinks map}"
  [steps cache]
  (let [processed (->> steps
                       resolve-symlink-paths
                       expand-symlink-folders
                       drop-context)
        merged (merge-steps processed)
        {:keys [unlinks symlinks]} (calculate-unlinks cache merged)
        plan (cond-> merged
               (seq unlinks) (assoc :fs/unlink unlinks))]
    ;; Validate the dependency graph
    (when-let [errors (g/validate plan)]
      (throw (ex-info "Invalid dependency graph" errors)))
    ;; Return plan, execution order, and symlinks for cache
    {:plan plan
     :order (g/topological-sort plan)
     :symlinks symlinks}))
