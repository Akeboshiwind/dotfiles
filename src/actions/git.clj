(ns actions.git
  (:require [actions :as a]
            [utils :as u]
            [babashka.fs :as fs]
            [display :as d]))

(defmethod a/requires :git/clone [_] :git)

(defn- clone! [opts url target ref]
  (let [{:keys [exit err]} (a/exec! opts ["git" "clone" url target])]
    (if (zero? exit)
      (if ref
        (a/exec! opts ["git" "-C" target "checkout" ref])
        {:exit 0 :err nil})
      {:exit exit :err err})))

(defn- update! [opts target ref]
  (let [{:keys [exit err]} (a/exec! opts ["git" "-C" target "fetch"])]
    (if (zero? exit)
      (if ref
        (a/exec! opts ["git" "-C" target "checkout" ref])
        (a/exec! opts ["git" "-C" target "pull"]))
      {:exit exit :err err})))

(defmethod a/install! :git/clone [_ opts items]
  (d/section "Cloning git repos"
    (map (fn [[target {:keys [url ref]}]]
           (let [expanded (u/expand-tilde target)
                 exists? (fs/exists? expanded)
                 {:keys [exit err]} (if exists?
                                      (update! opts expanded ref)
                                      (clone! opts url expanded ref))]
             {:label (str (name target) (when ref (str " @ " ref)))
              :status (if (zero? exit) :ok :error)
              :message err}))
         items)))
