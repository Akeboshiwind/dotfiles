(ns actions.npm
  (:require [actions :as a]
            [display :as d]))

(defn- install-one [pkg _opts]
  (let [{:keys [exit err]} (a/exec! ["npm" "install" "-g" (name pkg)])]
    {:label (name pkg)
     :status (if (zero? exit) :ok :error)
     :message err}))

(defmethod a/install! :pkg/npm [_ items]
  (d/section "Installing npm packages"
             (map (fn [[pkg opts]] (install-one pkg opts)) items)))
