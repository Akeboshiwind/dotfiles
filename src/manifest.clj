(ns manifest
  (:require [clojure.edn :as edn]
            [clojure.java.io :as io]
            [clojure.string :as str]
            [babashka.fs :as fs]))

(defn parse-secrets'
  "Pure parse of secrets.edn content into the secrets map.
   Returns nil when the content is still git-crypt ciphertext."
  [content]
  (when-not (str/starts-with? content "\u0000GITCRYPT\u0000")
    (edn/read-string content)))

(def ^:private secrets
  (delay
    (let [secrets-file "secrets.edn"]
      (if (fs/exists? secrets-file)
        (parse-secrets' (slurp secrets-file))
        {}))))

(defn secret-reader'
  "Pure secret lookup. Returns value or throws if not found.
   A nil secrets-map means secrets.edn is still encrypted."
  [secrets-map key]
  (let [value (get secrets-map key ::not-found)]
    (cond
      (nil? secrets-map)
      (throw (ex-info (str "Secret not found: " key " (secrets.edn is still encrypted)")
                      {:key key :encrypted true}))

      (= value ::not-found)
      (throw (ex-info (str "Secret not found: " key) {:key key}))

      :else value)))

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

(defn all-secrets
  "The parsed secrets map (secrets.edn), or nil while it is still encrypted.
   Used to fold secret values into the manifest identity, so changing a secret
   invalidates a captured plan."
  []
  @secrets)

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

(defn root
  "The directory syn reads its manifest from."
  []
  (str (fs/canonicalize ".")))

(defn exclusive-entry
  "The plan entry for the managers declared exclusive: one :syn/exclusive node
   per manager, run after all of that manager's installs. nil for none."
  [managers]
  (when-not (or (nil? managers) (set? managers))
    (throw (ex-info ":syn/exclusive must be a set of managers" {:value managers})))
  (when (seq managers)
    {:step {:syn/exclusive (into {} (map (fn [m] [m {:dep/requires #{[:complete m]}}])) managers)}
     :source nil}))

(defn load-manifest
  "Load plan from manifest.edn, resolving all entries.
   Returns [{:step map :source string-or-nil} ...]."
  []
  (let [{:keys [plan] :as root-manifest} (edn/read-string {:readers edn-readers} (slurp "manifest.edn"))
        exclusive (exclusive-entry (:syn/exclusive root-manifest))]
    (cond-> (mapv resolve-entry plan)
      exclusive (conj exclusive))))
