(ns actions.mise
  (:require [actions :as a]
            [cheshire.core :as json]
            [display :as d]
            [facts :as f]
            [outcome :as o]
            [utils.sh :as sh]))

(defmethod a/requires :pkg/mise [_] :pkg/mise)

(defn installed-map
  "Return {tool-name #{version ...}} of installed mise tools."
  []
  (let [raw (-> (d/with-spinner "Listing mise tools"
                  (sh/query! `installed-map ["mise" "ls" "--installed" "--json"]))
                :out
                (json/parse-string true))]
    (into {} (map (fn [[tool versions]]
                    [(name tool) (into #{} (map :version) versions)]))
          raw)))

(defn outdated-map
  "Return {tool-name {:current ... :latest ...}} from `mise outdated`.
   Only includes tools that have an upgrade available."
  []
  (let [raw (-> (d/with-spinner "Checking for outdated mise tools"
                  (sh/query! `outdated-map ["mise" "outdated" "--json"]))
                :out
                (json/parse-string true))]
    (into {} (map (fn [[tool {:keys [current latest]}]]
                    [(name tool) {:current current :latest latest}]))
          raw)))

(defn orphans
  "Find mise tools installed but not declared."
  [installed-tools declared-items]
  (let [declared (into #{} (map (comp name key)) declared-items)]
    (->> (keys installed-tools)
         (remove declared)
         (map (fn [n] [(keyword n) {}]))
         (into {}))))

(defmethod a/run-query :mise [[_ what]]
  (case what
    :installed (installed-map)
    :outdated (outdated-map)))

(defmethod a/orphan-queries :pkg/mise [_ _]
  #{[:command "mise"] [:mise :installed]})

(defmethod a/orphans :pkg/mise [_ declared facts]
  (when (f/value facts [:command "mise"])
    (let [result (orphans (f/value facts [:mise :installed]) declared)]
      (when (seq result)
        {:pkg/mise-uninstall result}))))

(defmethod a/queries :pkg/mise [_ declared]
  (cond-> #{[:mise :installed]}
    (some (fn [[_ opts]] (= "latest" (:version opts))) declared) (conj [:mise :outdated])))

(defmethod a/check :pkg/mise [_ key opts facts]
  (if-not (:version opts)
    (o/error "Version required")
    (let [tool-name (name key)
          versions  (get (f/value facts [:mise :installed]) tool-name)]
      (cond
        (nil? versions)
        (o/drift :missing)

        (= "latest" (:version opts))
        (if-let [{:keys [current latest]} (get (f/value facts [:mise :outdated]) tool-name)]
          (o/version-drift current latest)
          o/satisfied)

        (contains? versions (:version opts))
        o/satisfied

        :else
        (o/version-drift (last (sort versions)) (:version opts))))))

(defmethod a/check :pkg/mise-uninstall [_ key opts _facts]
  (o/drift :orphan))

(defmethod a/install! :pkg/mise [type opts items _facts]
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

(defmethod a/install! :pkg/mise-uninstall [type opts items _facts]
  (a/simple-install type opts "Uninstalling mise orphans"
    (fn [tool _] ["mise" "uninstall" (name tool)])
    items))
