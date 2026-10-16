(ns actions.git
  (:require [actions :as a]
            [utils :as u]
            [babashka.fs :as fs]
            [babashka.process :as process]
            [clojure.string :as str]
            [display :as d]
            [facts :as f]
            [outcome :as o]))

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

(defmethod a/queries :git/clone [_ declared]
  (into #{} (map (fn [[target _]] [:git :head (u/expand-tilde target)])) declared))

(defmethod a/run-query :git [[_ _ expanded]]
  (if-not (fs/exists? expanded)
    {:exists? false}
    {:exists? true
     :head (str/trim (:out (process/shell {:out :string :err :string :continue true}
                                          "git" "-C" expanded "rev-parse" "HEAD")))}))

(defmethod a/check :git/clone [_ key opts facts]
  (let [{:keys [ref]} opts
        {:keys [exists? head]} (f/value facts [:git :head (u/expand-tilde key)])]
    (if-not exists?
      (o/drift :missing)
      (if ref
        (if (str/starts-with? head ref)
          o/satisfied
          (o/drift :outdated))
        ;; No ref pinned: existence satisfies, but the repo will never be
        ;; updated by syn — surface that in the plan report.
        (assoc o/satisfied :message "no ref declared — repo is never updated")))))

(defmethod a/install! :git/clone [_ opts items]
  (d/section "Cloning git repos"
    (map (fn [[target {:keys [url ref]}]]
           (let [expanded (u/expand-tilde target)
                 exists? (fs/exists? expanded)
                 {:keys [exit err]} (if exists?
                                      (update! opts expanded ref)
                                      (clone! opts url expanded ref))]
             {:action [:git/clone target]
              :label (str (name target) (when ref (str " @ " ref)))
              :status (if (zero? exit) :ok :error)
              :message err}))
         items)))
