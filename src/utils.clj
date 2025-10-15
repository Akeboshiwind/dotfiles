(ns utils
  (:require [clojure.string :as str]))

(defn- expand-tilde [path]
  (str/replace path #"^~" (System/getProperty "user.home")))
