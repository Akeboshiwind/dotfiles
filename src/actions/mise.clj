(ns actions.mise
  (:require [actions :as a]
            [babashka.process :as process]
            [cheshire.core :as json]
            [outcome :as o]
            [utils :as u]))

(defmethod a/requires :pkg/mise [_] :pkg/mise)

(defn installed-map
  "Return {tool-name #{version ...}} of installed mise tools."
  []
  (let [raw (-> (process/shell {:out :string :err :string} "mise" "ls" "--installed" "--json")
                :out
                (json/parse-string true))]
    (into {} (map (fn [[tool versions]]
                    [(name tool) (into #{} (map :version) versions)]))
          raw)))

(defn orphans
  "Find mise tools installed but not declared."
  [installed-tools declared-items]
  (let [declared (into #{} (map (comp name key)) declared-items)]
    (->> (keys installed-tools)
         (remove declared)
         (map (fn [n] [(keyword n) {}]))
         (into {}))))

(defmethod a/orphans :pkg/mise [_ declared]
  (when (u/command-exists? "mise")
    (let [result (orphans (installed-map) declared)]
      (when (seq result)
        {:pkg/mise-uninstall result}))))

(def ^:dynamic *installed-cache* (delay (installed-map)))

(defmethod a/check :pkg/mise [_ key opts]
  (if-not (:version opts)
    (o/error "Version required")
    (let [installed @*installed-cache*
          tool-name (name key)
          versions (get installed tool-name)]
      (cond
        (nil? versions) (o/drift :missing)
        (contains? versions (:version opts)) o/satisfied
        :else (assoc (o/drift :outdated) :message (str (last (sort versions)) " → " (:version opts)))))))

(defmethod a/check :pkg/mise-uninstall [_ key opts]
  (o/drift :orphan))

(defmethod a/install! :pkg/mise [type opts items]
  (a/simple-install type opts "Installing mise tools"
    (fn [tool item-opts] (str (name tool) "@" (:version item-opts)))
    (fn [tool {:keys [version global]}]
      (let [tool-str (str (name tool) "@" version)]
        (if global
          ["mise" "use" "--global" tool-str]
          ["mise" "install" tool-str])))
    items))

;; -- Uninstall orphans

(defmethod a/requires :pkg/mise-uninstall [_] [:complete :pkg/mise])

(defmethod a/install! :pkg/mise-uninstall [type opts items]
  (a/simple-install type opts "Uninstalling mise orphans"
    (fn [tool _] ["mise" "uninstall" (name tool)])
    items))
