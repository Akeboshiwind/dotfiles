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

(defmethod a/run-query :mise [[_ what]]
  (case what
    :installed (installed-map)
    :outdated (outdated-map)))

(defmethod a/extras-queries :pkg/mise [_] #{[:command "mise"] [:mise :installed]})

(defmethod a/extras :pkg/mise [_ declared facts]
  (if (f/value facts [:command "mise"])
    (->> (keys (f/value facts [:mise :installed])) (remove declared) sort (mapv (fn [n] {:name n})))
    []))

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

(defmethod a/install! :pkg/mise [type opts items _facts]
  (a/simple-install type opts "Installing mise tools"
    (fn [tool item-opts] (str (name tool) "@" (:version item-opts)))
    (fn [tool {:keys [version global]}]
      (let [tool-str (str (name tool) "@" version)]
        (if global
          ["mise" "use" "--global" tool-str]
          ["mise" "install" tool-str])))
    items))

(defmethod a/remove-extras! :pkg/mise [type opts extras _facts]
  (a/simple-install type opts "Uninstalling mise tools"
    (fn [tool _] ["mise" "uninstall" tool])
    (into {} (map (fn [{n :name}] [n {}])) extras)))
