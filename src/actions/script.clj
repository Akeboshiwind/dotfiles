(ns actions.script
  (:require [actions.core :as a]))

(defmethod a/install! :pkg/script [_ items {:keys [run-command]}]
  (doseq [[script-name {:keys [path src]}] items]
    (let [cmd (cond
                path ["bash" path]
                src  ["bash" "-c" src]
                :else (throw (ex-info "Script must have :path or :src" {:script script-name})))]
      (run-command (str "script - " (name script-name)) cmd))))
