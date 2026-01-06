(ns actions.mas
  (:require [actions :as a]))

(defmethod a/install! :pkg/mas [_ opts items]
  (a/simple-install opts "Installing Mac App Store apps"
    (fn [app-name _] (name app-name))
    (fn [_app-name app-id] ["mas" "install" app-id])
    items))
