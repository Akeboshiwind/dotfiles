(ns actions.npm
  (:require [actions :as a]
            [cheshire.core :as json]
            [clojure.string :as str]
            [display :as d]
            [facts :as f]
            [outcome :as o]
            [utils.sh :as sh]))

(defmethod a/requires :pkg/npm [_] :pkg/npm)

(defn installed-set
  "Return #{name ...} of globally installed npm packages."
  []
  (let [result (d/with-spinner "Listing global npm packages"
                 (sh/query! `installed-set {:continue true}
                            ["npm" "list" "-g" "--depth=0" "--json"]))]
    (if (zero? (:exit result))
      (into #{} (keys (get (json/parse-string (:out result)) "dependencies")))
      #{})))

(defn outdated-map
  "Return {name {:current v1 :latest v2}} from `npm outdated -g --json`.
   Only includes packages that have an upgrade available.
   `npm outdated` exits non-zero when anything is outdated, so the exit
   code is ignored and parsing relies on the JSON body."
  []
  (let [raw (-> (d/with-spinner "Checking for outdated npm packages"
                  (sh/query! `outdated-map {:continue true}
                             ["npm" "outdated" "-g" "--json"]))
                :out)]
    (if (str/blank? raw)
      {}
      (into {}
        (keep (fn [[pkg info]]
                (let [current (get info "current")
                      latest  (get info "latest")]
                  (when (and current latest (not= current latest))
                    [pkg {:current current :latest latest}]))))
        (json/parse-string raw)))))

(defmethod a/run-query :npm [[_ what]]
  (case what
    :installed (installed-set)
    :outdated (outdated-map)))

(defn- pkg-name-from-url
  "Extract package name from a URL.
   e.g. 'https://…/happy-coder-0.13.0.tgz' → 'happy-coder'"
  [url]
  (let [filename (last (str/split url #"/"))
        base     (str/replace filename #"\.tgz$" "")]
    (str/replace base #"-\d[^-]*$" "")))

(defmethod a/queries :pkg/npm [_ _] #{[:npm :installed] [:npm :outdated]})

(defmethod a/check :pkg/npm [_ key _opts facts]
  (let [k        (if (keyword? key) (name key) (str key))
        pkg-name (if (str/starts-with? k "http")
                   (pkg-name-from-url k)
                   k)
        out-info (get (f/value facts [:npm :outdated]) pkg-name)]
    (cond
      out-info    (o/version-drift (:current out-info) (:latest out-info))
      (contains? (f/value facts [:npm :installed]) pkg-name) o/satisfied
      :else       (o/drift :missing))))

(def ^:private builtin-packages
  "Packages that ship with Node and should not be treated as orphans."
  #{"npm" "corepack"})

(defn orphans
  "Find globally installed npm packages not declared in the manifest."
  [installed-names declared-items]
  (let [declared (into #{} (map (comp name key)) declared-items)]
    (->> installed-names
         (remove declared)
         (remove builtin-packages)
         (map (fn [n] [(keyword n) {}]))
         (into {}))))

(defmethod a/orphan-queries :pkg/npm [_ _]
  #{[:command "npm"] [:npm :installed]})

(defmethod a/orphans :pkg/npm [_ declared facts]
  (when (f/value facts [:command "npm"])
    (let [result (orphans (f/value facts [:npm :installed]) declared)]
      (when (seq result)
        {:pkg/npm-uninstall result}))))

(defmethod a/check :pkg/npm-uninstall [_ _key _opts _facts]
  (o/drift :orphan))

(defn install-cmd
  [pkg {:keys [args]}]
  (-> ["npm" "install" "-g"]
      (into args)
      (conj (name pkg))))

(defmethod a/install! :pkg/npm [type opts items]
  (a/simple-install type opts "Installing npm packages"
    install-cmd
    items))

;; -- Uninstall orphans

(defmethod a/requires :pkg/npm-uninstall [_] [:complete :pkg/npm])

(defmethod a/install! :pkg/npm-uninstall [type opts items]
  (a/simple-install type opts "Uninstalling npm orphans"
    (fn [pkg _] ["npm" "uninstall" "-g" (name pkg)])
    items))
