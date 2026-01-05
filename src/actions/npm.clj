(ns actions.npm
  (:require [actions.core :as a]))

(defmethod a/install! :pkg/npm [_ items]
  (doseq [[pkg _opts] items]
    (a/with-label (str "npm - " (name pkg)) ["npm" "install" "-g" (name pkg)])))
