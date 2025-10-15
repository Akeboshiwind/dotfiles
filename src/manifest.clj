(ns manifest
  (:require [clojure.edn :as edn]
            [clojure.java.io :as io]))

(defn read-all-forms
  "Read all top-level forms from an EDN file"
  [file]
  (let [base-dir (.getParent (io/file file))]
    (with-open [r (io/reader file)]
      (let [pbr (java.io.PushbackReader. r)]
        (loop [forms []]
          (let [form (edn/read {:eof ::eof} pbr)]
            (if (= form ::eof)
              forms
              (-> forms
                  (conj (assoc form :context {:source-dir base-dir}))
                  recur))))))))

(defn resolve-path
  "Resolve a path or keyword to a file path"
  [entry]
  (cond
    (string? entry) entry
    (keyword? entry) (str "cfg/" (name entry) "/base.edn")
    :else (throw (ex-info "Invalid entry in manifest" {:entry entry}))))

(defn resolve-entry
  "Resolve an entry which can be a string, keyword, or map"
  [entry]
  (if (map? entry)
    [entry]
    (-> entry resolve-path read-all-forms)))

(defn load-manifest
  "Load all config files from manifest"
  []
  (let [raw-manifest (slurp "manifest.edn")
        {:keys [bootstrap config]} (edn/read-string raw-manifest)]
    {:bootstrap bootstrap
     :config (mapcat resolve-entry config)}))
