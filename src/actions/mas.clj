(ns actions.mas
  (:require [actions.core :as a]
            [display :as d]))

(defn- install-one [app-name app-id]
  (let [{:keys [exit]} (a/exec! ["mas" "install" app-id])]
    {:label (str app-name)
     :status (if (zero? exit) :ok :error)}))

(defmethod a/install! :pkg/mas [_ items]
  (d/section "Installing Mac App Store apps"
             (map (fn [[app-name app-id]] (install-one app-name app-id)) items)))
