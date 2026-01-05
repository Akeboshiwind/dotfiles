(ns actions.script
  (:require [actions.core :as a]
            [display :as d]))

(defn- run-one [script-name {:keys [path src]}]
  (let [cmd (cond
              path ["bash" path]
              src  ["bash" "-c" src]
              :else (throw (ex-info "Script must have :path or :src" {:script script-name})))
        {:keys [exit]} (a/exec! cmd)]
    {:label (name script-name)
     :status (if (zero? exit) :ok :error)}))

(defmethod a/install! :pkg/script [_ items]
  (d/section "Running scripts"
             (map (fn [[name opts]] (run-one name opts)) items)))
