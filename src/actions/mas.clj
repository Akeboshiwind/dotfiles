(ns actions.mas
  (:require [actions :as a]
            [clojure.string :as str]
            [display :as d]
            [facts :as f]
            [outcome :as o]
            [utils.sh :as sh]))

(defmethod a/requires :pkg/mas [_] :pkg/mas)

(defn installed-map
  "Return {id app-name} of installed Mac App Store apps."
  []
  (let [lines (-> (d/with-spinner "Listing Mac App Store apps"
                    (sh/query! `installed-map ["mas" "list"]))
                  :out
                  str/split-lines)]
    (into {} (keep (fn [line]
                     (when-let [[_ id app-name] (re-matches #"\s*(\d+)\s+(.+?)(?:\s+\(.*\))?\s*$" line)]
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

(defmethod a/run-query :mas [[_ what]]
  (case what
    :installed (installed-map)))

(defmethod a/orphan-queries :pkg/mas [_ _]
  #{[:command "mas"] [:mas :installed]})

(defmethod a/orphans :pkg/mas [_ declared facts]
  (when (f/value facts [:command "mas"])
    (let [result (orphans (f/value facts [:mas :installed]) declared)]
      (when (seq result)
        {:pkg/mas-uninstall result}))))

(defmethod a/queries :pkg/mas [_ _] #{[:mas :installed]})

(defmethod a/check :pkg/mas [_ _key opts facts]
  (let [app-id (if (map? opts) (:id opts) opts)
        installed (f/value facts [:mas :installed])]
    (if (contains? installed app-id)
      o/satisfied
      (o/drift :missing))))

(defmethod a/check :pkg/mas-uninstall [_ key opts _facts]
  (o/drift :orphan))

(defmethod a/install! :pkg/mas [type opts items _facts]
  (a/simple-install type opts "Installing Mac App Store apps"
    (fn [app-name _] (name app-name))
    (fn [_app-name app-opts]
      (let [app-id (if (map? app-opts) (:id app-opts) app-opts)]
        ["mas" "install" (str app-id)]))
    items))

;; -- Uninstall orphans

(defmethod a/requires :pkg/mas-uninstall [_] [:complete :pkg/mas])

(defmethod a/install! :pkg/mas-uninstall [type opts items _facts]
  (a/simple-install type opts "Uninstalling Mac App Store orphans"
    (fn [app-id opts] (or (:name opts) (str app-id)))
    (fn [app-id _] ["mas" "uninstall" (str (if (keyword? app-id) (name app-id) app-id))])
    items))
