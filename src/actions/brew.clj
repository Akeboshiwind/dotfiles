(ns actions.brew
  (:require [actions :as a]))

(defmethod a/requires :pkg/brew [_] :pkg/brew)
(defmethod a/requires :brew/service [_] :brew/service)

(defmethod a/install! :pkg/brew [_ opts items]
  (a/simple-install opts "Installing brew packages"
    (fn [pkg {:keys [head cask]}]
      (cond-> ["brew" "install"]
        cask (conj "--cask")
        true (conj (name pkg))
        head (conj "--HEAD")))
    items))

(defmethod a/install! :brew/service [_ opts items]
  (a/simple-install opts "Starting brew services"
    (fn [svc {:keys [restart sudo]}]
      (let [cmd (if restart
                  ["brew" "services" "restart" (name svc)]
                  ["brew" "services" "start" (name svc)])]
        (if sudo
          (into ["sudo"] cmd)
          cmd)))
    items))
