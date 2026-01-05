(ns actions.mise
  (:require [actions.core :as a]
            [display :as d]))

(defn- install-one [tool {:keys [version global]}]
  (let [tool-str (str (name tool) "@" version)
        cmd (if global
              ["mise" "use" "--global" tool-str]
              ["mise" "install" tool-str])
        {:keys [exit]} (a/exec! cmd)]
    {:label tool-str
     :status (if (zero? exit) :ok :error)}))

(defmethod a/install! :pkg/mise [_ items]
  (d/section "Installing mise tools"
             (map (fn [[tool opts]] (install-one tool opts)) items)))
