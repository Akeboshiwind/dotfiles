(ns actions.script
  (:require [actions.core :as a]))

(defmethod a/install! :pkg/script [_ items]
  (doseq [[script-name {:keys [path src]}] items]
    (let [cmd (cond
                path ["bash" path]
                src  ["bash" "-c" src]
                :else (throw (ex-info "Script must have :path or :src" {:script script-name})))]
      (a/with-label (str "script - " (name script-name)) cmd))))
