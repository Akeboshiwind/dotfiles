(ns actions.mise
  (:require [actions.core :as a]))

(defmethod a/install! :pkg/mise [_ items]
  (doseq [[tool {:keys [version global]}] items]
    (let [tool-str (str (name tool) "@" version)]
      (if global
        (a/with-label (str "mise (use global) - " tool-str) ["mise" "use" "--global" tool-str])
        (a/with-label (str "mise - " tool-str) ["mise" "install" tool-str])))))
