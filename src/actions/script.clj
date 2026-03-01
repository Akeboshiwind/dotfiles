(ns actions.script
  (:require [actions :as a]
            [babashka.process :as process]
            [display :as d]
            [outcome :as o]))

(defmethod a/requires :pkg/script [_] nil)

(defmethod a/validate :pkg/script [_ items]
  (for [[script-name opts] items
        :when (not (or (:path opts) (:src opts)))]
    {:action :pkg/script
     :key script-name
     :error "Either :path or :src required"}))

(defmethod a/check :pkg/script [_ key opts]
  (let [{:keys [path src check]} opts]
    (cond
      (not (or path src))
      (o/error "Either :path or :src required")

      (nil? check)
      o/unknown

      :else
      (let [cmd (if (:path check) ["bash" (:path check)] ["bash" "-c" (:src check)])
            result (apply process/shell {:out :string :err :string :continue true} cmd)]
        (if (zero? (:exit result))
          o/satisfied
          (o/drift :missing))))))

(defmethod a/install! :pkg/script [_ opts items]
  (d/section "Running scripts"
    (map (fn [[script-name {:keys [path src env]}]]
           (let [cmd (cond
                       path ["bash" path]
                       src  ["bash" "-c" src]
                       :else (throw (ex-info "Script must have :path or :src"
                                             {:script script-name})))
                 {:keys [exit err]} (a/exec! (cond-> opts env (assoc :env env)) cmd)]
             {:action [:pkg/script script-name]
              :label (name script-name)
              :status (if (zero? exit) :ok :error)
              :message err}))
         items)))
