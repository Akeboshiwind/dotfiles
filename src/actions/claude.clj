(ns actions.claude
  (:require [clojure.string :as str]
            [actions :as a]
            [display :as d]))

(defmethod a/requires :claude/marketplace [_] :claude/marketplace)
(defmethod a/requires :claude/plugin [_] :claude/plugin)
(defmethod a/requires :claude/mcp [_] :claude/mcp)

(defmethod a/install! :claude/marketplace [_ opts items]
  (a/simple-install opts "Adding Claude marketplaces"
    (fn [marketplace-name {:keys [source]}]
      ["claude" "plugin" "marketplace" "add" (or source (name marketplace-name))])
    items))

(defmethod a/install! :claude/plugin [_ opts items]
  (a/simple-install opts "Installing Claude plugins"
    (fn [plugin _item-opts]
      ["claude" "plugin" "install" (name plugin)])
    items))

;; MCP has special remove-then-add logic, doesn't fit simple-install
(defn- add-mcp [opts server-name {:keys [command args env scope] :or {scope "user"}}]
  (let [name-str (name server-name)
        env-args (mapcat (fn [[k v]] ["-e" (str (name k) "=" v)]) env)
        cmd-args (if args (into [command] args) [command])
        remove-cmd ["claude" "mcp" "remove" name-str "--scope" scope]
        add-cmd (vec (concat ["claude" "mcp" "add" name-str "--scope" scope]
                             env-args
                             ["--"]
                             cmd-args))]
    ;; Remove first, then add
    (let [{remove-exit :exit remove-err :err} (a/exec! opts remove-cmd)
          ;; Ignore "not found" errors, but fail on unexpected remove errors
          remove-failed? (and (not (zero? remove-exit))
                              (not (str/includes? (or remove-err "") "No such server")))]
      (if remove-failed?
        {:label name-str
         :status :error
         :message remove-err}
        (let [{:keys [exit err]} (a/exec! opts add-cmd)]
          {:label name-str
           :status (if (zero? exit) :ok :error)
           :message err})))))

(defmethod a/install! :claude/mcp [_ opts items]
  (d/section "Adding Claude MCP servers"
             (map (fn [[server-name item-opts]] (add-mcp opts server-name item-opts)) items)))
