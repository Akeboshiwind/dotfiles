(ns actions.script
  (:require [actions :as a]
            [babashka.process :as process]
            [cache :as c]
            [display :as d]
            [facts :as f]
            [outcome :as o]))

(defmethod a/requires :pkg/script [_] nil)

(defn- script-content
  "Get the content string of a script for hashing."
  [{:keys [path src]}]
  (cond
    path (slurp path)
    src src))

(defn- bash-command [{:keys [path src]}]
  (if path ["bash" path] ["bash" "-c" src]))

(defn- check-query
  "The query that runs a script's :check, or nil when the check needs none."
  [key {:keys [path src check] :as opts}]
  (when (and (or path src) check)
    [:script (name key) (select-keys opts [:path :src :check])]))

(defmethod a/queries :pkg/script [_ declared]
  (into #{} (keep (fn [[k opts]] (check-query k opts))) declared))

(defmethod a/run-query :script [[_ script-name {:keys [check] :as opts}]]
  (let [current-hash (c/content-hash (script-content opts))
        cached (c/get-script (or @a/*cache* {}) script-name)
        changed? (or (nil? cached)
                     (not= current-hash (:content-hash cached)))
        cmd (bash-command (if (string? check) {:src check} check))]
    (zero? (:exit (apply process/shell {:out :string :err :string :continue true
                                        :extra-env {"DOTFILES_CONTENT_CHANGED" (str changed?)}}
                         cmd)))))

(defmethod a/check :pkg/script [_ key opts facts]
  (let [{:keys [path src check]} opts]
    (cond
      (not (or path src))
      (o/error "Either :path or :src required")

      (nil? check)
      o/unknown

      (f/value facts (check-query key opts))
      o/satisfied

      :else
      (o/drift :missing))))

(defmethod a/install! :pkg/script [_ opts items _facts]
  (d/section "Running scripts"
    (map (fn [[script-name {:keys [path src env] :as script-opts}]]
           (let [cmd (if (or path src)
                       (bash-command script-opts)
                       (throw (ex-info "Script must have :path or :src"
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
