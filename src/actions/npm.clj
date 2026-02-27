(ns actions.npm
  (:require [actions :as a]))

(defmethod a/requires :pkg/npm [_] :pkg/npm)

(defmethod a/install! :pkg/npm [type opts items]
  (a/simple-install type opts "Installing npm packages"
    (fn [pkg _item-opts]
      ["npm" "install" "-g" (name pkg)])
    items))
