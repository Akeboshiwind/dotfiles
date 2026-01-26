(ns actions.mise
  (:require [actions :as a]))

(defmethod a/requires :pkg/mise [_] :pkg/mise)

(defmethod a/validate :pkg/mise [_ items]
  (for [[tool opts] items
        :when (not (:version opts))]
    {:action :pkg/mise
     :key tool
     :error "Version required"}))

(defmethod a/install! :pkg/mise [_ opts items]
  (a/simple-install opts "Installing mise tools"
    (fn [tool item-opts] (str (name tool) "@" (:version item-opts)))
    (fn [tool {:keys [version global]}]
      (let [tool-str (str (name tool) "@" version)]
        (if global
          ["mise" "use" "--global" tool-str]
          ["mise" "install" tool-str])))
    items))
