(ns actions.mise
  (:require [actions :as a]
            [cheshire.core :as json]
            [clojure.string :as str]
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

(defmethod a/manifest :pkg/mise [_] {:syn/exclusive {:pkg/mise {}}})

(defmethod a/extras-queries :pkg/mise [_] #{[:command "mise"] [:mise :installed]})

(defmethod a/extras :pkg/mise [_ declared facts]
  (if (f/value facts [:command "mise"])
    (->> (keys (f/value facts [:mise :installed])) (remove declared) sort (mapv (fn [n] {:name n})))
    []))

(defn- global-version
  [{:keys [version global]}]
  (when global version))

(defn- install-versions
  [{:keys [version global]}]
  (if (and version (not global)) #{version} #{}))

(defn- declared-versions [opts]
  (cond-> (install-versions opts)
    (global-version opts) (conj (global-version opts))))

(defmethod a/queries :pkg/mise [_ declared]
  (cond-> #{[:mise :installed]}
    (some (fn [[_ opts]] (contains? (declared-versions opts) "latest")) declared) (conj [:mise :outdated])))

(defmethod a/check :pkg/mise [_ key opts facts]
  (let [declared (declared-versions opts)]
    (if (empty? declared)
      (o/error "Version required")
      (let [tool-name (name key)
            versions  (get (f/value facts [:mise :installed]) tool-name)
            missing   (->> declared (remove #{"latest"}) (remove #(contains? versions %)) sort first)]
        (cond
          (nil? versions)
          (o/drift :missing)

          missing
          (o/version-drift (last (sort versions)) missing)

          (contains? declared "latest")
          (if-let [{:keys [current latest]} (get (f/value facts [:mise :outdated]) tool-name)]
            (o/version-drift current latest)
            o/satisfied)

          :else
          o/satisfied)))))

(defn- install-commands [tool opts]
  (let [spec #(str (name tool) "@" %)]
    (cond-> []
      (global-version opts)
      (conj ["mise" "use" "--global" (spec (global-version opts))])

      (seq (install-versions opts))
      (conj (into ["mise" "install"] (map spec) (sort (install-versions opts)))))))

(defn- exec-all!
  [opts cmds]
  (or (some (fn [cmd]
              (let [result (a/exec! opts cmd)]
                (when-not (zero? (:exit result)) result)))
            cmds)
      {:exit 0}))

(defmethod a/install! :pkg/mise [type opts items _facts]
  (d/section "Installing mise tools"
    (map (fn [[tool item-opts]]
           (let [{:keys [exit err]} (exec-all! opts (install-commands tool item-opts))]
             {:action [type tool]
              :label (str/join " " (map #(str (name tool) "@" %) (sort (declared-versions item-opts))))
              :status (if (zero? exit) :ok :error)
              :message err}))
         items)))

(defmethod a/remove-extras! :pkg/mise [type opts extras _facts]
  (a/simple-install type opts "Uninstalling mise tools"
    (fn [tool _] ["mise" "uninstall" tool])
    (into {} (map (fn [{n :name}] [n {}])) extras)))
