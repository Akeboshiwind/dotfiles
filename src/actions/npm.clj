(ns actions.npm
  (:require [actions :as a]))

(defmethod a/install! :pkg/npm [_ items]
  (a/simple-install "Installing npm packages"
    (fn [pkg _opts]
      ["npm" "install" "-g" (name pkg)])
    items))
