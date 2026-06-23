(ns actions.npm
  (:require [actions :as a]
            [babashka.process :as process]
            [cheshire.core :as json]
            [clojure.string :as str]
            [outcome :as o]
            [utils :as u]))

(defmethod a/requires :pkg/npm [_] :pkg/npm)

(def ^:private ^:dynamic *installed-cache*
  (delay
    (let [result (process/shell {:out :string :err :string :continue true}
                                "npm" "list" "-g" "--depth=0" "--json")]
      (if (zero? (:exit result))
        (into #{} (keys (get (json/parse-string (:out result)) "dependencies")))
        #{}))))

(defn outdated-map
  "Return {name {:current v1 :latest v2}} from `npm outdated -g --json`.
   Only includes packages that have an upgrade available.
   `npm outdated` exits non-zero when anything is outdated, so the exit
   code is ignored and parsing relies on the JSON body."
  []
  (let [raw (-> (process/shell {:out :string :err :string :continue true}
                               "npm" "outdated" "-g" "--json")
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

(def ^:private ^:dynamic *outdated-cache* (delay (outdated-map)))

(defn- pkg-name-from-url
  "Extract package name from a URL.
   e.g. 'https://…/happy-coder-0.13.0.tgz' → 'happy-coder'"
  [url]
  (let [filename (last (str/split url #"/"))
        base     (str/replace filename #"\.tgz$" "")]
    (str/replace base #"-\d[^-]*$" "")))

(defmethod a/check :pkg/npm [_ key opts]
  (let [k        (if (keyword? key) (name key) (str key))
        pkg-name (if (str/starts-with? k "http")
                   (pkg-name-from-url k)
                   k)
        out-info (get @*outdated-cache* pkg-name)]
    (cond
      out-info    (assoc (o/drift :outdated)
                         :message (str (:current out-info) " → " (:latest out-info)))
      (contains? @*installed-cache* pkg-name) o/satisfied
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

(defmethod a/orphans :pkg/npm [_ declared]
  (when (u/command-exists? "npm")
    (let [result (orphans @*installed-cache* declared)]
      (when (seq result)
        {:pkg/npm-uninstall result}))))

(defmethod a/check :pkg/npm-uninstall [_ _key _opts]
  (o/drift :orphan))

(defmethod a/install! :pkg/npm [type opts items]
  (a/simple-install type opts "Installing npm packages"
    (fn [pkg _item-opts]
      ["npm" "install" "-g" (name pkg)])
    items))

;; -- Uninstall orphans

(defmethod a/requires :pkg/npm-uninstall [_] [:complete :pkg/npm])

(defmethod a/install! :pkg/npm-uninstall [type opts items]
  (a/simple-install type opts "Uninstalling npm orphans"
    (fn [pkg _] ["npm" "uninstall" "-g" (name pkg)])
    items))
