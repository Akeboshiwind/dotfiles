(ns actions.claude
  (:require [actions.core :as a]
            [display :as d]))

(defn- add-marketplace [marketplace-name {:keys [source]}]
  (let [src (or source (name marketplace-name))
        {:keys [exit]} (a/exec! ["claude" "plugin" "marketplace" "add" src])]
    {:label (name marketplace-name)
     :status (if (zero? exit) :ok :error)}))

(defn- install-plugin [plugin _opts]
  (let [{:keys [exit]} (a/exec! ["claude" "plugin" "install" (name plugin)])]
    {:label (name plugin)
     :status (if (zero? exit) :ok :error)}))

(defn- add-mcp [server-name {:keys [command args env scope] :or {scope "user"}}]
  (let [name-str (name server-name)
        env-args (mapcat (fn [[k v]] ["-e" (str (name k) "=" v)]) env)
        cmd-args (if args (into [command] args) [command])
        remove-cmd ["claude" "mcp" "remove" name-str "--scope" scope]
        add-cmd (vec (concat ["claude" "mcp" "add" name-str "--scope" scope]
                             env-args
                             ["--"]
                             cmd-args))]
    ;; Remove first (ignore errors if doesn't exist), then add
    (a/exec! remove-cmd)
    (let [{:keys [exit]} (a/exec! add-cmd)]
      {:label name-str
       :status (if (zero? exit) :ok :error)})))

(defmethod a/install! :claude/marketplace [_ items]
  (d/section "Adding Claude marketplaces"
             (map (fn [[name opts]] (add-marketplace name opts)) items)))

(defmethod a/install! :claude/plugin [_ items]
  (d/section "Installing Claude plugins"
             (map (fn [[name opts]] (install-plugin name opts)) items)))

(defmethod a/install! :claude/mcp [_ items]
  (d/section "Adding Claude MCP servers"
             (map (fn [[name opts]] (add-mcp name opts)) items)))
