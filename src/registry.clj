(ns registry
  "Auto-discovers and loads all action namespace implementations.
   Requiring this namespace loads all action namespaces from src/actions/."
  (:require [babashka.fs :as fs]
            [clojure.string :as str]))

(def ^:private actions-dir
  (fs/path (fs/parent (fs/absolutize *file*)) "actions"))

(defn- discover-action-namespaces
  "Find all .clj files in the actions/ directory beside this file and return
   their namespace symbols."
  []
  (->> (fs/glob actions-dir "*.clj")
       (map (fn [path]
              (-> (str (fs/file-name path))
                  (str/replace #"\.clj$" "")
                  (str/replace "_" "-")
                  (->> (str "actions."))
                  symbol)))))

;; Load all action namespaces at require time
(doseq [ns-sym (discover-action-namespaces)]
  (require ns-sym))

(defn ensure-loaded!
  "No-op — action namespaces are loaded when this namespace is required."
  []
  nil)
