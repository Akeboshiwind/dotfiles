(ns actions.mas
  (:require [actions :as a]))

(defmethod a/requires :pkg/mas [_] :pkg/mas)

(defmethod a/install! :pkg/mas [type opts items]
  (a/simple-install type opts "Installing Mac App Store apps"
    (fn [app-name _] (name app-name))
    (fn [_app-name app-id] ["mas" "install" app-id])
    items))
