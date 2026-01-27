(ns manifest
  (:require [clojure.edn :as edn]
            [clojure.java.io :as io]
            [babashka.fs :as fs]))

(def ^:private secrets
  (delay
    (let [secrets-file "secrets.edn"]
      (if (fs/exists? secrets-file)
        (edn/read-string (slurp secrets-file))
        {}))))

(defn secret-reader'
  "Pure secret lookup. Returns value or throws if not found."
  [secrets-map key]
  (let [value (get secrets-map key ::not-found)]
    (if (= value ::not-found)
      (throw (ex-info (str "Secret not found: " key) {:key key}))
      value)))

(defn- secret-reader
  "Reader function for #secret tag - looks up key in secrets.edn"
  [key]
  (secret-reader' @secrets key))

(defn validate-secrets'
  "Pure validation of secrets map. Returns seq of error maps for empty values."
  [secrets-map]
  (for [[key value] secrets-map
        :when (and (not= value :secret/disabled)
                   (or (nil? value)
                       (and (string? value) (empty? value))))]
    {:action :secret
     :key key
     :error "Empty value (use :secret/disabled to disable)"}))

(defn validate-secrets
  "Validate all secrets. Returns seq of error maps for empty values."
  []
  (validate-secrets' @secrets))

(def ^:private edn-readers
  {'secret secret-reader})

(defn entry->path
  "Convert manifest entry to file path. Returns nil for maps."
  [entry]
  (cond
    (string? entry)  entry
    (keyword? entry) (str "cfg/" (name entry) "/manifest.edn")
    :else nil))

(defn resolve-entry'
  "Pure entry resolution. Takes a read function for file entries.
   Returns {:step map :source string-or-nil}."
  [read-fn entry]
  (cond
    (string? entry)  (read-fn entry)
    (keyword? entry) (read-fn (str "cfg/" (name entry) "/manifest.edn"))
    (map? entry)     {:step entry :source nil}
    :else (throw (ex-info "Invalid entry in manifest" {:entry entry}))))

(defn- read-edn-file
  "Read EDN file, returning {:step content :source dir}."
  [file]
  (let [base-dir (.getParent (io/file file))]
    {:step (edn/read-string {:readers edn-readers} (slurp file))
     :source base-dir}))

(defn- resolve-entry
  "Resolve a plan entry: string/keyword -> file, map -> inline.
   Returns {:step map :source string-or-nil}."
  [entry]
  (resolve-entry' read-edn-file entry))

(defn load-manifest
  "Load plan from manifest.edn, resolving all entries.
   Returns [{:step map :source string-or-nil} ...]."
  []
  (let [{:keys [plan]} (edn/read-string {:readers edn-readers} (slurp "manifest.edn"))]
    (mapv resolve-entry plan)))
