(ns actions.mas
  (:require [actions.core :as a]))

(defmethod a/install! :pkg/mas [_ items]
  (doseq [[app-name app-id] items]
    (a/with-label (str "MAS - " app-name) ["mas" "install" app-id])))
