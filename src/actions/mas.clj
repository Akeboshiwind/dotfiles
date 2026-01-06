(ns actions.mas
  (:require [actions :as a]))

(defmethod a/install! :pkg/mas [_ items]
  (a/simple-install "Installing Mac App Store apps"
    (fn [app-name _] (str app-name))
    (fn [_app-name app-id] ["mas" "install" app-id])
    items))
