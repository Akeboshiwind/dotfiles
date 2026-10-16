(ns actions.bbin
  (:require [actions :as a]
            [babashka.fs :as fs]
            [clojure.edn :as edn]
            [display :as d]
            [facts :as f]
            [outcome :as o]
            [utils.sh :as sh]))

(defmethod a/requires :pkg/bbin [_] :pkg/bbin)

(defn installed-set
  "Return #{name ...} of installed bbin scripts."
  []
  (d/with-spinner "Listing bbin scripts"
    (->> (sh/query! `installed-set ["bbin" "ls" "--edn"])
         :out
         edn/read-string
         keys
         (map name)
         set)))

(defn orphans
  "Find bbin scripts installed but not declared."
  [installed-names declared-items]
  (let [declared (into #{} (map (comp name key)) declared-items)]
    (->> installed-names
         (remove declared)
         (map (fn [n] [(keyword n) {}]))
         (into {}))))

(defmethod a/run-query :bbin [[_ what]]
  (case what
    :installed (installed-set)))

(defmethod a/orphan-queries :pkg/bbin [_ _]
  #{[:command "bbin"] [:bbin :installed]})

(defmethod a/orphans :pkg/bbin [_ declared facts]
  (when (f/value facts [:command "bbin"])
    (let [result (orphans (f/value facts [:bbin :installed]) declared)]
      (when (seq result)
        {:pkg/bbin-uninstall result}))))

(defmethod a/queries :pkg/bbin [_ _] #{[:bbin :installed]})

(defmethod a/check :pkg/bbin [_ key _opts facts]
  (let [installed (f/value facts [:bbin :installed])]
    (if (contains? installed (name key))
      o/satisfied
      (o/drift :missing))))

(defmethod a/check :pkg/bbin-uninstall [_ key opts _facts]
  (o/drift :orphan))

(defn- build-cmd [pkg opts]
  (let [pkg-name (name pkg)
        ;; For local projects, use the directory path as the package arg
        package-arg (if-let [local (:local opts)]
                      (str (fs/canonicalize local))
                      (or (:url opts) pkg-name))
        as-name (or (:as opts) (when (or (:url opts) (:local opts)) pkg-name))
        base-cmd ["bbin" "install" package-arg]
        opts-flags (cond-> []
                     as-name             (into ["--as" as-name])
                     (:git/sha opts)     (into ["--git/sha" (:git/sha opts)])
                     (:git/tag opts)     (into ["--git/tag" (:git/tag opts)])
                     (:git/url opts)     (into ["--git/url" (:git/url opts)])
                     (:latest-sha opts)  (conj "--latest-sha")
                     (:local/root opts)  (into ["--local/root" (:local/root opts)])
                     (:main-opts opts)   (into ["--main-opts" (str (:main-opts opts))])
                     (:mvn/version opts) (into ["--mvn/version" (:mvn/version opts)])
                     (:ns-default opts)  (into ["--ns-default" (:ns-default opts)])
                     (:tool opts)        (conj "--tool"))]
    (into base-cmd opts-flags)))

(defmethod a/install! :pkg/bbin [type opts items _facts]
  (a/simple-install type opts "Installing bbin packages" build-cmd items))

;; -- Uninstall orphans

(defmethod a/requires :pkg/bbin-uninstall [_] [:complete :pkg/bbin])

(defmethod a/install! :pkg/bbin-uninstall [type opts items _facts]
  (a/simple-install type opts "Uninstalling bbin orphans"
    (fn [pkg _] ["bbin" "uninstall" (name pkg)])
    items))
