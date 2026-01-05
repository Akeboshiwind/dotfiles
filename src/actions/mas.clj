(ns actions.mas
  (:require [actions.core :as a]))

(defmethod a/install! :pkg/mas [_ items {:keys [run-command]}]
  (doseq [[app-name app-id] items]
    (run-command (str "MAS - " app-name) ["mas" "install" app-id])))
