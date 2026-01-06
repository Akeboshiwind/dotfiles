(ns actions.mise
  (:require [actions :as a]
            [display :as d]))

(defn- install-one [tool {:keys [version global]}]
  (let [tool-str (str (name tool) "@" version)
        cmd (if global
              ["mise" "use" "--global" tool-str]
              ["mise" "install" tool-str])
        {:keys [exit err]} (a/exec! cmd)]
    {:label tool-str
     :status (if (zero? exit) :ok :error)
     :message err}))

(defmethod a/validate :pkg/mise [_ items]
  (for [[tool opts] items
        :when (not (:version opts))]
    {:action :pkg/mise
     :key tool
     :error "Version required"}))

(defmethod a/install! :pkg/mise [_ items]
  (d/section "Installing mise tools"
             (map (fn [[tool opts]] (install-one tool opts)) items)))
