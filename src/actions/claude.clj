(ns actions.claude
  (:require [actions.core :as a]))

(defmethod a/install! :claude/marketplace [_ items {:keys [run-command]}]
  (doseq [[marketplace-name {:keys [source]}] items]
    (let [src (or source (name marketplace-name))
          cmd ["claude" "plugin" "marketplace" "add" src]]
      (run-command (str "claude marketplace - " (name marketplace-name)) cmd))))

(defmethod a/install! :claude/plugin [_ items {:keys [run-command]}]
  (doseq [[plugin _opts] items]
    (run-command (str "claude plugin - " (name plugin)) ["claude" "plugin" "install" (name plugin)])))

(defmethod a/install! :claude/mcp [_ items {:keys [run-command exec!]}]
  (doseq [[server-name {:keys [command args env scope] :or {scope "user"}}] items]
    (let [name-str (name server-name)
          env-args (mapcat (fn [[k v]] ["-e" (str (name k) "=" v)]) env)
          cmd-args (if args (into [command] args) [command])
          remove-cmd ["claude" "mcp" "remove" name-str "--scope" scope]
          add-cmd (vec (concat ["claude" "mcp" "add" name-str "--scope" scope]
                               env-args
                               ["--"]
                               cmd-args))]
      ;; Remove first (ignore errors if doesn't exist), then add
      (exec! remove-cmd)
      (run-command (str "claude mcp - " name-str) add-cmd))))
