(ns cache
  (:require [babashka.fs :as fs]
            [clojure.java.io :as io]
            [clojure.edn :as edn]))

(def cache-dir
  (let [xdg-cache (System/getenv "XDG_CACHE_HOME")
        base (or xdg-cache (str (System/getProperty "user.home") "/.cache"))]
    (str base "/dotfiles")))

(def cache-file (str cache-dir "/cache.edn"))

(defn save-cache!
  "Atomically saves cache data to the cache file.
   Creates the cache directory if it doesn't exist."
  [data]
  (fs/create-dirs cache-dir)
  (let [tmp (fs/create-temp-file {:dir cache-dir
                                  :prefix "cache-"
                                  :suffix ".edn"})]
    (try
      (spit (str tmp) (pr-str data))
      (fs/move tmp cache-file {:replace-existing true})
      (finally
        (when (fs/exists? tmp)
          (fs/delete tmp))))))

(defn load-cache
  "Loads the cache from disk. Returns nil if file doesn't exist.
   Throws on corrupt cache."
  []
  (when (fs/exists? cache-file)
    (edn/read-string (slurp cache-file))))

(defn content-hash
  "SHA-256 hash of a string."
  [s]
  (let [digest (java.security.MessageDigest/getInstance "SHA-256")
        bytes (.digest digest (.getBytes (str s) "UTF-8"))]
    (apply str (map #(format "%02x" %) bytes))))

(defn script-record
  "Build a script cache record from content string."
  [content]
  {:timestamp (java.util.Date.)
   :content-hash (content-hash content)})

(defn get-script
  "Get cached script record by name. Returns nil if not cached."
  [cache script-name]
  (get-in cache [:scripts script-name]))

(defn put-script
  "Update cache with a script record."
  [cache script-name record]
  (assoc-in cache [:scripts script-name] record))
