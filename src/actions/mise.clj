(ns actions.mise
  (:require [actions :as a]))

(defmethod a/validate :pkg/mise [_ items]
  (for [[tool opts] items
        :when (not (:version opts))]
    {:action :pkg/mise
     :key tool
     :error "Version required"}))

(defmethod a/install! :pkg/mise [_ items]
  (a/simple-install "Installing mise tools"
    (fn [tool opts] (str (name tool) "@" (:version opts)))
    (fn [tool {:keys [version global]}]
      (let [tool-str (str (name tool) "@" version)]
        (if global
          ["mise" "use" "--global" tool-str]
          ["mise" "install" tool-str])))
    items))
