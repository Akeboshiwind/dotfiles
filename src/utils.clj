(ns utils
  (:require [babashka.process :as process]
            [clojure.string :as str]))

(defn expand-tilde
  "Expand leading ~ in path to user's home directory."
  [path]
  (str/replace path #"^~" (System/getProperty "user.home")))

(defn command-exists?
  "Check if a command is available on PATH."
  [cmd]
  (zero? (:exit (process/shell {:out :string :err :string :continue true} "command" "-v" cmd))))
