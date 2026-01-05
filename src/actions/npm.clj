(ns actions.npm
  (:require [actions.core :as a]))

(defmethod a/install! :pkg/npm [_ items {:keys [run-command]}]
  (doseq [[pkg _opts] items]
    (run-command (str "npm - " (name pkg)) ["npm" "install" "-g" (name pkg)])))
