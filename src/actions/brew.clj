(ns actions.brew
  (:require [actions :as a]))

(defmethod a/install! :pkg/brew [_ items]
  (a/simple-install "Installing brew packages"
    (fn [pkg {:keys [head]}]
      (into ["brew" "install" (name pkg)] (when head ["--HEAD"])))
    items))
