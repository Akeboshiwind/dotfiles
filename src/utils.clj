(ns utils
  (:require [babashka.fs :as fs]
            [clojure.string :as str]))

(defn expand-tilde
  "Expand leading ~ in path to user's home directory."
  [path]
  (str/replace path #"^~" (System/getProperty "user.home")))

(defn command-exists?
  "Check if a command is available on PATH."
  [cmd]
  (some? (fs/which cmd)))
