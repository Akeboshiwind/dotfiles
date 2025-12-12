(ns manifest
  (:require [clojure.edn :as edn]
            [clojure.java.io :as io]))

(defn- read-edn-file
  "Read EDN file, adding :context with source directory"
  [file]
  (let [base-dir (.getParent (io/file file))]
    (-> (slurp file)
        edn/read-string
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
