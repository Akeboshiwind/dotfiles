(ns actions.npm
  (:require [actions :as a]))

(defmethod a/install! :pkg/npm [_ opts items]
  (a/simple-install opts "Installing npm packages"
    (fn [pkg _item-opts]
      ["npm" "install" "-g" (name pkg)])
    items))
