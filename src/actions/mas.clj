(ns actions.mas
  (:require [actions :as a]
            [babashka.process :as process]
            [clojure.string :as str]
            [outcome :as o]))

(defmethod a/requires :pkg/mas [_] :pkg/mas)

(defn installed-map
  "Return {id app-name} of installed Mac App Store apps."
  []
  (let [lines (-> (process/shell {:out :string :err :string} "mas" "list")
                  :out
                  str/split-lines)]
    (into {} (keep (fn [line]
                     (when-let [[_ id app-name] (re-matches #"(\d+)\s+(.+?)(?:\s+\(.*\))?\s*$" line)]
                       [(parse-long id) (str/trim app-name)])))
          lines)))

(defn orphans
  "Find MAS apps installed but not declared."
  [installed-apps declared-items]
  (let [declared-ids (into #{} (map (fn [[_ opts]] (if (map? opts) (:id opts) opts)))
                           declared-items)]
    (->> installed-apps
         (remove (fn [[id _]] (contains? declared-ids id)))
         (map (fn [[id app-name]] [id {:name app-name}]))
         (into {}))))

(defmethod a/orphans :pkg/mas [_ declared]
  (let [result (orphans (installed-map) declared)]
    (when (seq result)
      {:pkg/mas-uninstall result})))

(def ^:dynamic *installed-cache* (delay (installed-map)))

(defmethod a/check :pkg/mas [_ key opts]
  (let [app-id (if (map? opts) (:id opts) opts)
        installed @*installed-cache*]
    (if (contains? installed app-id)
      o/satisfied
      (o/drift :missing))))

(defmethod a/check :pkg/mas-uninstall [_ key opts]
  (o/drift :orphan))

(defmethod a/install! :pkg/mas [type opts items]
  (a/simple-install type opts "Installing Mac App Store apps"
    (fn [app-name _] (name app-name))
    (fn [_app-name app-opts]
      (let [app-id (if (map? app-opts) (:id app-opts) app-opts)]
        ["mas" "install" (str app-id)]))
    items))

;; -- Uninstall orphans

(defmethod a/requires :pkg/mas-uninstall [_] [:complete :pkg/mas])

(defmethod a/install! :pkg/mas-uninstall [type opts items]
  (a/simple-install type opts "Uninstalling Mac App Store orphans"
    (fn [app-id opts] (or (:name opts) (str app-id)))
    (fn [app-id _] ["mas" "uninstall" (str (if (keyword? app-id) (name app-id) app-id))])
    items))
