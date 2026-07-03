(ns plan
  (:require [clojure.string :as str]
            [clojure.java.io :as io]
            [clojure.set :as set]
            [actions :as a]
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
  (mapv (fn [{:keys [step source]}]
          {:step (-> step
                     (resolve-paths-in-action! source :fs/symlink)
                     (resolve-paths-in-action! source :fs/symlink-folder))
           :source source})
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
  (mapv (fn [{:keys [step source]}]
          {:step (expand-symlink-folder! step)
           :source source})
        entries))

;; >> Validate and merge steps

(defn find-duplicate-keys
  "Find keys that appear in multiple entries within the same action type.
   Takes [{:step map :source string} ...]. Returns seq of error maps."
  [entries]
  (let [steps (map :step entries)
        action-types (->> steps (mapcat keys) distinct)]
    (for [action-type action-types
          :let [;; Collect [key source] pairs for this action type
                key-sources (->> entries
                                 (mapcat (fn [{:keys [step source]}]
                                           (for [k (keys (get step action-type))]
                                             [k source])))
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
  (apply merge-with merge (map :step entries)))

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

;; >> Calculate package orphans

(defn- orphan-types
  "Return all action types that have a non-default orphans implementation."
  []
  (->> (methods a/orphans)
       keys
       (remove #{:default})))

(defn calculate-orphans
  "Query live state and compute orphan removal actions for all action types
   with orphan detection, not just those in the plan.
   Each a/orphans impl returns a plan fragment or nil, possibly spanning
   several orphan action types (e.g. {:pkg/brew-uninstall {...} :brew/untap {...}}).
   When an orphan type requires [:complete base] and the base type is absent
   from the plan, the base is injected as an empty entry so the dependency
   graph resolves."
  [plan]
  (let [merged (->> (orphan-types)
                    (keep #(a/orphans % (get plan % {})))
                    (apply merge {}))
        missing-bases (->> (keys merged)
                           (keep (fn [orphan-type]
                                   (let [req (a/requires orphan-type)]
                                     (when (and (vector? req) (= :complete (first req)))
                                       (second req)))))
                           (remove #(or (contains? plan %)
                                        (contains? merged %))))]
    (reduce (fn [acc base] (assoc acc base {})) merged missing-bases)))

;; >> Plan builder

(defn build!
  "Build plan from entries. Takes [{:step map :source string} ...].
   Returns {:plan map :order [[type key] ...] :symlinks map :errors [...]}
   Impure: reads filesystem for path canonicalization, directory listing, and package queries."
  [entries cache]
  (let [processed (->> entries
                       resolve-symlink-paths!
                       expand-symlink-folders!)
        duplicate-errors (find-duplicate-keys processed)
        merged (merge-steps processed)
        {:keys [unlinks symlinks]} (calculate-unlinks cache merged)
        orphans (calculate-orphans merged)
        plan (cond-> merged
               (seq unlinks) (assoc :fs/unlink unlinks)
               (seq orphans) (merge orphans))]
    {:plan plan
     :symlinks symlinks
     :errors duplicate-errors}))
