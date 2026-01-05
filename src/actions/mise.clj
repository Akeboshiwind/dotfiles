(ns actions.mise
  (:require [actions.core :as a]))

(defmethod a/install! :pkg/mise [_ items {:keys [run-command]}]
  (doseq [[tool {:keys [version global]}] items]
    (let [tool-str (str (name tool) "@" version)]
      (if global
        (run-command (str "mise (use global) - " tool-str) ["mise" "use" "--global" tool-str])
        (run-command (str "mise - " tool-str) ["mise" "install" tool-str])))))
