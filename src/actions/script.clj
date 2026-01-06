(ns actions.script
  (:require [actions :as a]))

(defmethod a/validate :pkg/script [_ items]
  (for [[script-name opts] items
        :when (not (or (:path opts) (:src opts)))]
    {:action :pkg/script
     :key script-name
     :error "Either :path or :src required"}))

(defmethod a/install! :pkg/script [_ opts items]
  (a/simple-install opts "Running scripts"
    (fn [script-name {:keys [path src]}]
      (cond
        path ["bash" path]
        src  ["bash" "-c" src]
        :else (throw (ex-info "Script must have :path or :src" {:script script-name}))))
    items))
