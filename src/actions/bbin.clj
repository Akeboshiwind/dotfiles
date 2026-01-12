(ns actions.bbin
  (:require [actions :as a]
            [babashka.fs :as fs]))

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

(defmethod a/install! :pkg/bbin [_ opts items]
  (a/simple-install opts "Installing bbin packages" build-cmd items))
