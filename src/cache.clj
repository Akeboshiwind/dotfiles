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
    (spit (str tmp) (pr-str data))
    (fs/move tmp cache-file {:replace-existing true})))

(defn load-cache
  "Loads the cache from disk. Returns nil if file doesn't exist.
   Throws on corrupt cache."
  []
  (when (fs/exists? cache-file)
    (edn/read-string (slurp cache-file))))
