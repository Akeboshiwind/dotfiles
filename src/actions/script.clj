(ns actions.script
  (:require [actions :as a]
            [display :as d]))

(defn- run-one [script-name {:keys [path src]}]
  (let [cmd (cond
              path ["bash" path]
              src  ["bash" "-c" src]
              :else (throw (ex-info "Script must have :path or :src" {:script script-name})))
        {:keys [exit err]} (a/exec! cmd)]
    {:label (name script-name)
     :status (if (zero? exit) :ok :error)
     :message err}))

(defmethod a/validate :pkg/script [_ items]
  (for [[script-name opts] items
        :when (not (or (:path opts) (:src opts)))]
    {:action :pkg/script
     :key script-name
     :error "Either :path or :src required"}))

(defmethod a/install! :pkg/script [_ items]
  (d/section "Running scripts"
             (map (fn [[name opts]] (run-one name opts)) items)))
