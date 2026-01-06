(ns actions.brew
  (:require [actions :as a]))

(defmethod a/install! :pkg/brew [_ opts items]
  (a/simple-install opts "Installing brew packages"
    (fn [pkg {:keys [head]}]
      (into ["brew" "install" (name pkg)] (when head ["--HEAD"])))
    items))
