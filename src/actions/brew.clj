(ns actions.brew
  (:require [actions.core :as a]))

(defmethod a/install! :pkg/brew [_ items {:keys [run-command]}]
  (doseq [[pkg {:keys [head]}] items]
    (let [cmd (into ["brew" "install" (name pkg)] (when head ["--HEAD"]))]
      (run-command (str "brew - " (name pkg)) cmd))))
