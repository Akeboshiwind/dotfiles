(ns actions.script
  (:require [actions :as a]
            [babashka.process :as process]
            [cache :as c]
            [display :as d]
            [outcome :as o]))

(defmethod a/requires :pkg/script [_] nil)

(defn- script-content
  "Get the content string of a script for hashing."
  [{:keys [path src]}]
  (cond
    path (slurp path)
    src src))

(defmethod a/check :pkg/script [_ key opts]
  (let [{:keys [path src check]} opts]
    (cond
      (not (or path src))
      (o/error "Either :path or :src required")

      (nil? check)
      o/unknown

      :else
      (let [content (script-content opts)
            current-hash (c/content-hash content)
            cached (c/get-script (or @a/*cache* {}) (name key))
            changed? (or (nil? cached)
                         (not= current-hash (:content-hash cached)))
            env {"DOTFILES_CONTENT_CHANGED" (str changed?)}
            cmd (if (:path check) ["bash" (:path check)] ["bash" "-c" (:src check)])
            result (apply process/shell {:out :string :err :string :continue true
                                         :extra-env env} cmd)]
        (if (zero? (:exit result))
          o/satisfied
          (o/drift :missing))))))

(defmethod a/install! :pkg/script [_ opts items]
  (d/section "Running scripts"
    (map (fn [[script-name {:keys [path src env] :as script-opts}]]
           (let [cmd (cond
                       path ["bash" path]
                       src  ["bash" "-c" src]
                       :else (throw (ex-info "Script must have :path or :src"
                                             {:script script-name})))
                 {:keys [exit err]} (a/exec! (cond-> opts env (assoc :env env)) cmd)
                 ok? (zero? exit)]
             ;; Record content hash on successful execution
             (when ok?
               (when-let [content (script-content script-opts)]
                 (swap! a/*cache* c/put-script (name script-name) (c/script-record content))))
             {:action [:pkg/script script-name]
              :label (name script-name)
              :status (if ok? :ok :error)
              :message err}))
         items)))
