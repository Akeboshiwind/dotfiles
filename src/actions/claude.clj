(ns actions.claude
  (:require [clojure.string :as str]
            [clojure.java.io :as io]
            [actions :as a]
            [babashka.fs :as fs]
            [cheshire.core :as json]
            [display :as d]
            [facts :as f]
            [outcome :as o]
            [utils.sh :as sh]))

(defmethod a/requires :claude/marketplace [_] :claude/marketplace)
(defmethod a/requires :claude/plugin [_] :claude/plugin)
(defmethod a/requires :claude/mcp [_] :claude/mcp)

(defn- read-json [path]
  (let [f (io/file (str (System/getProperty "user.home") path))]
    (when (fs/exists? f)
      (json/parse-string (slurp f) true))))

(defn- installed-plugins []
  (or (:plugins (read-json "/.claude/plugins/installed_plugins.json")) {}))

(defmethod a/queries :claude/mcp [_ _] #{[:claude :mcp]})

(defmethod a/check :claude/mcp [_ key {:keys [scope] :or {scope "user"}} facts]
  ;; syn manages machine-global state, so only user-scope servers (recorded
  ;; in ~/.claude.json) can be declared; project/local registrations belong
  ;; to the projects they serve.
  (if (not= scope "user")
    (o/error "only user-scope MCP servers can be managed from dotfiles")
    (if (contains? (f/value facts [:claude :mcp]) (keyword (name key)))
      o/satisfied
      (o/drift :missing))))

(defmethod a/queries :claude/marketplace [_ _] #{[:claude :marketplaces]})

(defmethod a/check :claude/marketplace [_ key opts facts]
  (let [source (or (:source opts) (name key))]
    (if (some (fn [[_k v]] (= source (get-in v [:source :repo]))) (f/value facts [:claude :marketplaces]))
      o/satisfied
      (o/drift :missing))))

(def ^:private ^:dynamic *marketplace-refresh*
  "Refreshes all marketplace catalogues from their sources (network).
   Forced at most once per run, before plugin version comparison — version
   drift can only be detected against a current catalogue."
  (delay (d/with-spinner "Fetching updates from Claude Marketplace"
           (sh/query! `*marketplace-refresh* {:continue true}
                      ["claude" "plugin" "marketplace" "update"]))))

(defn catalogue-version
  "Version of a plugin in the local marketplace checkout, or nil when the
   catalogue does not record one (e.g. remote plugin sources)."
  [marketplace plugin-name]
  (let [base (str (System/getProperty "user.home") "/.claude/plugins/marketplaces/" marketplace)
        mp-file (io/file base ".claude-plugin/marketplace.json")]
    (when (fs/exists? mp-file)
      (let [entry (->> (json/parse-string (slurp mp-file) true)
                       :plugins
                       (filter #(= plugin-name (:name %)))
                       first)]
        (or (:version entry)
            (when-let [src (:source entry)]
              (when (string? src)
                (let [pf (io/file base src ".claude-plugin/plugin.json")]
                  (when (fs/exists? pf)
                    (:version (json/parse-string (slurp pf) true)))))))))))

(defn- installed-plugin-entry
  "Find [plugin-id records] in the plugin cache for a plugin name."
  [plugin-cache n]
  (some (fn [[k v]] (when (str/starts-with? (name k) (str n "@")) [(name k) v]))
        plugin-cache))

(defn- refreshed-catalogue-version
  "catalogue-version against a catalogue refreshed from its source this run."
  [marketplace plugin-name]
  @*marketplace-refresh*
  (catalogue-version marketplace plugin-name))

(defmethod a/run-query :claude [[_ what n]]
  (case what
    :mcp (or (:mcpServers (read-json "/.claude.json")) {})
    :marketplaces (or (read-json "/.claude/plugins/known_marketplaces.json") {})
    :plugins (installed-plugins)
    :catalogue (when-let [[plugin-id _] (installed-plugin-entry (installed-plugins) n)]
                 (refreshed-catalogue-version (second (str/split plugin-id #"@" 2)) n))))

(defmethod a/queries :claude/plugin [_ declared]
  (into #{[:claude :plugins]}
        (map (fn [[k _]] [:claude :catalogue (name k)]))
        declared))

(defmethod a/check :claude/plugin [_ key _opts facts]
  (let [n (name key)]
    (if-let [[_ records] (installed-plugin-entry (f/value facts [:claude :plugins]) n)]
      (let [installed-version (:version (first records))
            latest (f/value facts [:claude :catalogue n])]
        (if (and installed-version latest (not= installed-version latest))
          (o/version-drift installed-version latest)
          o/satisfied))
      (o/drift :missing))))

(defmethod a/install! :claude/marketplace [type opts items _facts]
  (a/simple-install type opts "Adding Claude marketplaces"
    (fn [marketplace-name {:keys [source]}]
      ["claude" "plugin" "marketplace" "add" (or source (name marketplace-name))])
    items))

(defmethod a/install-queries :claude/plugin [_ _] #{[:claude :plugins]})

(defmethod a/install! :claude/plugin [type opts items facts]
  (a/simple-install type opts "Installing Claude plugins"
    (fn [plugin _item-opts]
      (let [n (name plugin)]
        ;; Outdated plugins are already installed — update instead of install.
        ;; update requires the marketplace-qualified id; the bare name is "not found".
        (if-let [[plugin-id _] (installed-plugin-entry (f/value facts [:claude :plugins]) n)]
          ["claude" "plugin" "update" plugin-id]
          ["claude" "plugin" "install" n])))
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
        {:action [:claude/mcp server-name]
         :label name-str
         :status :error
         :message remove-err}
        (let [{:keys [exit err]} (a/exec! opts add-cmd)]
          {:action [:claude/mcp server-name]
           :label name-str
           :status (if (zero? exit) :ok :error)
           :message err})))))

(defmethod a/install! :claude/mcp [_ opts items _facts]
  (d/section "Adding Claude MCP servers"
             (map (fn [[server-name item-opts]] (add-mcp opts server-name item-opts)) items)))
