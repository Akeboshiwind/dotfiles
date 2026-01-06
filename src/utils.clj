(ns utils
  (:require [clojure.string :as str]))

(defn expand-tilde
  "Expand leading ~ in path to user's home directory."
  [path]
  (str/replace path #"^~" (System/getProperty "user.home")))
