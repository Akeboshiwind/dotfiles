(ns actions.mise
  (:require [actions :as a]
            [cheshire.core :as json]
            [clojure.string :as str]
            [display :as d]
            [facts :as f]
            [outcome :as o]
            [utils.sh :as sh]))

(defmethod a/requires :pkg/mise [_] :pkg/mise)

(defn- versions-by-tool
  "{tool-name #{version ...}} from the JSON `mise ls --json` prints."
  [out]
  (into {} (map (fn [[tool versions]]
                  [(name tool) (into #{} (map :version) versions)]))
        (json/parse-string out true)))

(defn installed-map
  "Return {tool-name #{version ...}} of installed mise tools."
  []
  (-> (d/with-spinner "Listing mise tools"
        (sh/query! `installed-map ["mise" "ls" "--installed" "--json"]))
      :out
      versions-by-tool))

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

(defn global-request
  "What mise's global config requests for `tool`, as `mise config get` prints
   it: a version for a plain request, TOML otherwise. nil when it has no entry."
  [tool]
  (let [{:keys [exit out]} (sh/query! `global-request {:continue true}
                                      ["mise" "config" "get" "--global" (str "tools." tool)])]
    (when (zero? exit) (str/trim out))))

(defn global-tools
  "The set of tools mise's global config requests."
  []
  ;; Run from /, where no project config loads, so the highest-precedence file is the global one
  (-> (sh/query! `global-tools ["mise" "-C" "/" "config" "ls" "--json"])
      :out
      (json/parse-string true)
      last
      :tools
      set))

(defmethod a/run-query :mise [[_ what tool]]
  (case what
    :installed (installed-map)
    :outdated (outdated-map)
    :global (global-request tool)
    :global-tools (global-tools)))

(defn- global-version [opts]
  (:global opts))

(defn- install-versions [{:keys [global install]}]
  (disj (set install) global))

(defn- declared-versions [opts]
  (cond-> (install-versions opts)
    (global-version opts) (conj (global-version opts))))

(defmethod a/manifest :pkg/mise [_] {:syn/exclusive {:pkg/mise {}}})

(defmethod a/extras-queries :pkg/mise [_]
  #{[:command "mise"] [:mise :installed] [:mise :global-tools]})

(defmethod a/extras :pkg/mise [_ declared facts]
  (if (f/value facts [:command "mise"])
    (let [installed (f/value facts [:mise :installed])
          requested (f/value facts [:mise :global-tools])]
      (->> (into (set (keys installed)) requested)
           (remove declared)
           sort
           (mapv (fn [n] {:name n
                          :installed? (contains? installed n)
                          :requested? (contains? requested n)}))))
    []))

(defn- shape-error
  [{:keys [global install] :as opts}]
  (cond
    (contains? opts :version) ":version is replaced by :global and :install"
    (not (or (nil? global) (string? global))) ":global must be one version string"
    (not (or (nil? install) (set? install))) ":install must be a set of version strings"))

(defmethod a/queries :pkg/mise [_ declared]
  (cond-> (into #{[:mise :installed]}
                (map (fn [[k _]] [:mise :global (name k)]))
                declared)
    (some (fn [[_ opts]] (contains? (declared-versions opts) "latest")) declared) (conj [:mise :outdated])))

(defn- request-label [request]
  (if request (str/replace request #"\s*\n\s*" " ") "unset"))

(defmethod a/check :pkg/mise [_ key opts facts]
  (let [declared (declared-versions opts)]
    (cond
      (shape-error opts)
      (o/error (shape-error opts))

      (empty? declared)
      (o/error "Version required: declare :global or :install")

      :else
      (let [tool-name (name key)
            versions  (get (f/value facts [:mise :installed]) tool-name)
            missing   (->> declared (remove #{"latest"}) (remove #(contains? versions %)) sort first)]
        (cond
          (nil? versions)
          (o/drift :missing)

          missing
          (o/version-drift (last (sort versions)) missing)

          (not= (global-version opts) (f/value facts [:mise :global tool-name]))
          (o/version-drift (request-label (f/value facts [:mise :global tool-name]))
                           (request-label (global-version opts)))

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

      ;; --no-prune: without it, mise also uninstalls versions no config requests, :install's among them
      (not (global-version opts))
      (conj ["mise" "unuse" "--global" "--no-prune" (name tool)])

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

(defn- removal-commands [{tool :name :keys [installed? requested?]}]
  (cond-> []
    requested? (conj ["mise" "unuse" "--global" "--no-prune" tool])
    installed? (conj ["mise" "uninstall" "--all" tool])))

(defmethod a/remove-extras! :pkg/mise [type opts extras _facts]
  (d/section "Removing undeclared mise tools"
    (map (fn [{tool :name :as extra}]
           (let [{:keys [exit err]} (exec-all! opts (removal-commands extra))]
             {:action [type tool]
              :label tool
              :status (if (zero? exit) :ok :error)
              :message err}))
         extras)))
