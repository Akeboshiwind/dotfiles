(ns cld.main
  "Main orchestration for cld."
  (:require [cld.core :as core]
            [cld.cli :as cli]
            [cld.shell :as sh]
            [clojure.string :as str]
            [babashka.fs :as fs]))

(defn enrich-session!
  "Add runtime details to a session map"
  [{:keys [name activity] :as session}]
  (let [path (sh/get-session-path! name)
        counts (sh/get-session-counts! name)]
    (merge session
           counts
           {:path path
            :activity-ago (core/format-time-ago activity (sh/now-epoch!))
            :is-claude-project? (and path (sh/claude-project?! path))})))

(defn realize-project!
  "Execute the project plan (clone, create dir, etc)"
  [{:keys [action path clone-url] :as plan}]
  (case action
    :clone-repo
    (do
      (sh/print! (core/format-info (str "Cloning " (last (str/split clone-url #"/")) "...")))
      (sh/ensure-dir! (str (fs/parent path)))
      (if (sh/clone-repo! clone-url path)
        (do (sh/print! (core/format-ok "Cloned successfully"))
            plan)
        (throw (ex-info "Clone failed" {:url clone-url :path path}))))

    :create-dir
    (do
      (sh/ensure-dir! path)
      plan)

    :use-existing
    plan))

(defn cmd-start! [{:keys [project opts]}]
  (let [resolved (core/resolve-project-input project)
        context {:cwd (sh/get-cwd!)
                 :projects-dir (sh/get-projects-dir!)
                 :path-exists? sh/dir-exists?!}
        plan (core/build-project-plan resolved context)
        plan (realize-project! plan)
        session-name (core/make-session-name {:project (:name plan)
                                              :suffix (:session-name opts)})
        windows (get opts :windows 1)]
    (if (sh/session-exists?! session-name)
      (do
        (sh/print! (core/format-info (str "Attaching to " session-name)))
        ;; Show current stats
        (let [{:keys [path windows panes]} (merge {:windows 0 :panes 0}
                                                   (sh/get-session-counts! session-name))]
          (when-let [p (sh/get-session-path! session-name)]
            (sh/print! (str "  " (core/format-dim p))))
          (sh/print! (str "  " (core/format-dim (str windows " windows, " panes " panes")))))
        (sh/exec-tmux-attach! session-name))
      (do
        (sh/print! (core/format-info (str "Creating " session-name)))
        (sh/print! (str "  " (core/colorize :cyan (:path plan))))
        ;; Create session with claude
        (apply sh/tmux! (core/build-tmux-args {:op :new-session
                                               :name session-name
                                               :path (:path plan)
                                               :cmd "claude"}))
        ;; Add more windows if requested
        (dotimes [_ (dec windows)]
          (apply sh/tmux! (core/build-tmux-args {:op :new-window
                                                 :name session-name
                                                 :path (:path plan)
                                                 :cmd "claude"})))
        (sh/print! (core/format-ok "Session created"))
        (sh/exec-tmux-attach! session-name)))))

(defn cmd-list! [{:keys [filter]}]
  (if-let [sessions (sh/get-sessions-raw!)]
    (let [enriched (map enrich-session! sessions)
          filtered (if filter
                     (filter #(str/includes? (:name %) filter) enriched)
                     enriched)]
      (sh/print! (core/format-session-list filtered)))
    (sh/print! (core/format-no-sessions))))

(defn cmd-kill! [{:keys [target]}]
  (let [full-name (core/ensure-prefix target)
        {:keys [exit]} (apply sh/tmux! (core/build-tmux-args {:op :kill-session :name full-name}))]
    (if (zero? exit)
      (sh/print! (core/format-ok (str "Killed " full-name)))
      ;; Try without prefix
      (let [{:keys [exit]} (apply sh/tmux! (core/build-tmux-args {:op :kill-session :name target}))]
        (if (zero? exit)
          (sh/print! (core/format-ok (str "Killed " target)))
          (sh/print-err! (core/format-error (str "Session not found: " target))))))))

(defn cmd-rename! [{:keys [old new]}]
  (let [old-name (core/ensure-prefix old)
        new-name (core/ensure-prefix new)
        {:keys [exit]} (sh/tmux! "rename-session" "-t" old-name new-name)]
    (if (zero? exit)
      (sh/print! (core/format-ok (str old-name " → " new-name)))
      (sh/print-err! (core/format-error "Failed to rename session")))))

(defn cmd-select! []
  (let [sessions (sh/get-sessions-raw!)]
    (if (empty? sessions)
      (sh/print! (core/format-error "No sessions found"))
      (do
        (sh/print! (core/colorize :blue "Select a session:"))
        (doseq [[i s] (map-indexed vector sessions)]
          (let [{:keys [windows]} (sh/get-session-counts! (:name s))
                path (sh/get-session-path! (:name s))]
            (sh/print! (str (core/colorize :green (str (inc i) ")")) " " (:name s)
                            " " (core/format-dim (str "(" windows " windows)"))))
            (when path
              (sh/print! (str "   " (core/format-dim path))))))
        (print "Choice: ")
        (flush)
        (when-let [choice (some-> (read-line) str/trim parse-long)]
          (when (and (pos? choice) (<= choice (count sessions)))
            (sh/exec-tmux-attach! (:name (nth sessions (dec choice))))))))))

(defn cmd-help! []
  (sh/print! (core/format-help)))

(defn -main [& args]
  ;; Check dependencies first
  (when-let [err (sh/check-deps!)]
    (sh/print-err! (core/format-error err))
    (System/exit 1))

  (let [{:keys [command message] :as parsed} (cli/parse-args args)]
    (case command
      :start  (cmd-start! parsed)
      :list   (cmd-list! parsed)
      :kill   (cmd-kill! parsed)
      :rename (cmd-rename! parsed)
      :select (cmd-select!)
      :help   (cmd-help!)
      :error  (do (sh/print-err! (core/format-error message))
                  (System/exit 1)))))
