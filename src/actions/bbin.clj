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

(defmethod a/run-query :bbin [[_ what]]
  (case what
    :installed (installed-set)))

(defmethod a/extras-queries :pkg/bbin [_] #{[:command "bbin"] [:bbin :installed]})

(defmethod a/extras :pkg/bbin [_ declared facts]
  (if (f/value facts [:command "bbin"])
    (->> (f/value facts [:bbin :installed]) (remove declared) sort (mapv (fn [n] {:name n})))
    []))

(defmethod a/queries :pkg/bbin [_ _] #{[:bbin :installed]})

(defmethod a/check :pkg/bbin [_ key _opts facts]
  (let [installed (f/value facts [:bbin :installed])]
    (if (contains? installed (name key))
      o/satisfied
      (o/drift :missing))))

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

(defmethod a/remove-extras! :pkg/bbin [type opts extras _facts]
  (a/simple-install type opts "Uninstalling bbin scripts"
    (fn [pkg _] ["bbin" "uninstall" pkg])
    (into {} (map (fn [{n :name}] [n {}])) extras)))
