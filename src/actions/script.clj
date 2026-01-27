(ns actions.script
  (:require [actions :as a]
            [display :as d]))

(defmethod a/requires :pkg/script [_] nil)

(defmethod a/validate :pkg/script [_ items]
  (for [[script-name opts] items
        :when (not (or (:path opts) (:src opts)))]
    {:action :pkg/script
     :key script-name
     :error "Either :path or :src required"}))

(defmethod a/install! :pkg/script [_ opts items]
  (d/section "Running scripts"
    (map (fn [[script-name {:keys [path src env]}]]
           (let [cmd (cond
                       path ["bash" path]
                       src  ["bash" "-c" src]
                       :else (throw (ex-info "Script must have :path or :src"
                                             {:script script-name})))
                 {:keys [exit err]} (a/exec! (cond-> opts env (assoc :env env)) cmd)]
             {:label (name script-name)
              :status (if (zero? exit) :ok :error)
              :message err}))
         items)))
