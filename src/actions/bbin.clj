(ns actions.bbin
  (:require [actions.core :as a]))

(defmethod a/install! :pkg/bbin [_ items]
  (doseq [[pkg opts] items]
    (let [pkg-name (name pkg)
          package-arg (or (:url opts) pkg-name)
          as-name (if (and (:url opts) (not (:as opts)))
                    pkg-name
                    (:as opts))
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
                       (:tool opts)        (conj "--tool"))
          cmd (into base-cmd opts-flags)]
      (a/with-label (str "bbin - " pkg-name) cmd))))
