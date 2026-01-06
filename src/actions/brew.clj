(ns actions.brew
  (:require [actions :as a]
            [display :as d]))

(defn- install-one [pkg {:keys [head]}]
  (let [cmd (into ["brew" "install" (name pkg)] (when head ["--HEAD"]))
        {:keys [exit err]} (a/exec! cmd)]
    {:label (name pkg)
     :status (if (zero? exit) :ok :error)
     :message err}))

(defmethod a/install! :pkg/brew [_ items]
  (d/section "Installing brew packages"
             (map (fn [[pkg opts]] (install-one pkg opts)) items)))
