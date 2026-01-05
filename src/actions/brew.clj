(ns actions.brew
  (:require [actions.core :as a]))

(defmethod a/install! :pkg/brew [_ items]
  (doseq [[pkg {:keys [head]}] items]
    (let [cmd (into ["brew" "install" (name pkg)] (when head ["--HEAD"]))]
      (a/with-label (str "brew - " (name pkg)) cmd))))
