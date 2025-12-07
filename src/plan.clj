(ns plan
  (:require [clojure.string :as str]
            [clojure.java.io :as io]
            [clojure.set :as set]
            [utils :as u]))


;; >> Resolve symlinks to root of repo

(defn- resolve-path [base-dir path]
  (if (str/starts-with? path "./")
    (str base-dir "/" (subs path 2))
    path))

(defn- resolve-paths-in-step [action {{:keys [source-dir]} :context :as step}]
  (if-let [symlinks (action step)]
    (->> symlinks
         (map (fn [[target source]] [target (resolve-path source-dir source)]))
         (into {})
         (assoc step action))
    step))

(defn resolve-symlink-paths [steps]
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

(defn expand-symlink-folders
  "Breakdown :fs/symlink-folders into individual :fs/symlinks"
  [steps]
  (mapv expand-symlink-folder steps))

(comment
  (expand-symlink-folders
    [{:pkg/brew {:gpg {}}
      :fs/symlink {"a" "b"}
      :fs/symlink-folder {"~/.gnupg" "./cfg/gpg/.gnupg"
                          "~/.aws" "./cfg/aws/.aws"}}])
  ;=>
  [{:pkg/brew {:gpg {}}
    :fs/symlink {"a" "b"
                 "~/.gnupg/gpg-agent.conf" "./cfg/gpg/.gnupg/gpg-agent.conf"
                 "~/.gnupg/gpg.conf" "./cfg/gpg/.gnupg/gpg.conf"
                 "~/.aws/config" "./cfg/aws/.aws/config"}}])



;; >> Drop context key (no longer needed)

(defn drop-context [steps]
  (mapv #(dissoc % :context) steps))



;; >> Merge mergable actions
;; TODO: Add more notes and tests for how this works

;; Whitelist of action types that can be merged
(def ^:private mergeable-action-types
  #{:pkg/brew
    :pkg/mise
    :pkg/mas
    :fs/symlink
    :osx/defaults})

(defn- remove-keys [m ks]
  (apply dissoc m ks))

(defn merge-all [action-maps]
  (let [all-mergeable (map #(select-keys % mergeable-action-types) action-maps)
        non-mergeable (map #(remove-keys % mergeable-action-types) action-maps)
        merged (apply merge-with merge all-mergeable)]
    (if (not-empty merged)
      (into [merged] non-mergeable)
      non-mergeable)))


;; >> Remove empty action maps

(defn remove-empty [action-maps]
  (filterv not-empty action-maps))



;; >> Plan builder

(defn build [steps]
  (reduce (fn [s opt] (opt s))
          steps
          [resolve-symlink-paths
           expand-symlink-folders
           drop-context
           merge-all
           remove-empty]))


;; >> Symlink cache management

(defn- collect-all-symlinks
  "Extracts all symlinks from steps into a single map.
   Values are converted to absolute paths for cache storage."
  [steps]
  (->> steps
       (map :fs/symlink)
       (apply merge)
       (map (fn [[target source]]
              [target (.getAbsolutePath (io/file source))]))
       (into {})))

(defn inject-unlink
  "Given the current cache and steps, computes stale symlinks
   and prepends an :fs/unlink action if needed.
   Returns {:steps [...] :symlinks {...}}."
  [cache steps]
  (let [all-symlinks (collect-all-symlinks steps)
        cached-symlinks (get cache :symlinks {})
        stale (set/difference (set (keys cached-symlinks))
                              (set (keys all-symlinks)))]
    {:steps (if (seq stale)
              (into [{:fs/unlink (select-keys cached-symlinks stale)}] steps)
              steps)
     :symlinks all-symlinks}))
