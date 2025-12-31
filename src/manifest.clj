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

(defn- secret-reader
  "Reader function for #secret tag - looks up key in secrets.edn"
  [key]
  (if-let [value (get @secrets key)]
    value
    (throw (ex-info (str "Secret not found: " key) {:key key}))))

(def ^:private edn-readers
  {'secret secret-reader})

(defn- read-edn-file
  "Read EDN file, adding :context with source directory"
  [file]
  (let [base-dir (.getParent (io/file file))]
    (-> (edn/read-string {:readers edn-readers} (slurp file))
        (assoc :context {:source-dir base-dir}))))

(defn- resolve-entry
  "Resolve a plan entry: string/keyword -> file, map -> inline"
  [entry]
  (cond
    (string? entry)  (read-edn-file entry)
    (keyword? entry) (read-edn-file (str "cfg/" (name entry) "/base.edn"))
    (map? entry)     entry
    :else (throw (ex-info "Invalid entry in manifest" {:entry entry}))))

(defn load-manifest
  "Load plan from manifest.edn, resolving all entries"
  []
  (let [{:keys [plan]} (edn/read-string (slurp "manifest.edn"))]
    (mapv resolve-entry plan)))
