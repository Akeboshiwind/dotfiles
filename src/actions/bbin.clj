(ns actions.bbin
  (:require [actions :as a]
            [babashka.fs :as fs]
            [babashka.process :as process]
            [clojure.edn :as edn]
            [outcome :as o]))

(defmethod a/requires :pkg/bbin [_] :pkg/bbin)

(defn installed-set
  "Return #{name ...} of installed bbin scripts."
  []
  (->> (process/shell {:out :string :err :string} "bbin" "ls" "--edn")
       :out
       edn/read-string
       keys
       (map name)
       set))

(defn orphans
  "Find bbin scripts installed but not declared."
  [installed-names declared-items]
  (let [declared (into #{} (map (comp name key)) declared-items)]
    (->> installed-names
         (remove declared)
         (map (fn [n] [(keyword n) {}]))
         (into {}))))

(defmethod a/orphans :pkg/bbin [_ declared]
  (let [result (orphans (installed-set) declared)]
    (when (seq result)
      {:pkg/bbin-uninstall result})))

(def ^:dynamic *installed-cache* (delay (installed-set)))

(defmethod a/check :pkg/bbin [_ key opts]
  (let [installed @*installed-cache*]
    (if (contains? installed (name key))
      o/satisfied
      (o/drift :missing))))

(defmethod a/check :pkg/bbin-uninstall [_ key opts]
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

(defmethod a/install! :pkg/bbin [type opts items]
  (a/simple-install type opts "Installing bbin packages" build-cmd items))

;; -- Uninstall orphans

(defmethod a/requires :pkg/bbin-uninstall [_] [:complete :pkg/bbin])

(defmethod a/status :pkg/bbin-uninstall [type items _ctx]
  (mapv (fn [[k _]]
          {:label (name k)
           :state :orphan
           :action [type k]})
        items))

(defmethod a/install! :pkg/bbin-uninstall [type opts items]
  (a/simple-install type opts "Uninstalling bbin orphans"
    (fn [pkg _] ["bbin" "uninstall" (name pkg)])
    items))
