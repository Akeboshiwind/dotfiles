(ns cld.shell
  "Side-effectful operations for cld."
  (:require [babashka.process :as p]
            [babashka.fs :as fs]
            [clojure.string :as str]))

;; =============================================================================
;; System Queries
;; =============================================================================

(defn get-cwd! []
  (str (fs/cwd)))

(defn get-env! [k]
  (System/getenv k))

(defn get-projects-dir! []
  (or (get-env! "CLD_PROJECTS_DIR")
      (str (fs/home) "/projects")))

(defn dir-exists?! [path]
  (fs/directory? path))

(defn now-epoch! []
  (quot (System/currentTimeMillis) 1000))

;; =============================================================================
;; Tmux Operations
;; =============================================================================

(defn tmux!
  "Run tmux command, return {:out :err :exit}"
  [& args]
  (let [result (apply p/shell {:out :string :err :string :continue true}
                      "tmux" args)]
    {:out (str/trim (or (:out result) ""))
     :err (str/trim (or (:err result) ""))
     :exit (:exit result)}))

(defn session-exists?! [name]
  (zero? (:exit (tmux! "has-session" "-t" name))))

(defn get-sessions-raw!
  "Get list of claude sessions with raw tmux data"
  []
  (let [{:keys [out exit]} (tmux! "ls" "-F" "#{session_name}|#{session_activity}")]
    (when (zero? exit)
      (->> (str/split-lines out)
           (filter #(str/starts-with? % "claude-"))
           (map (fn [line]
                  (let [[name activity] (str/split line #"\|")]
                    {:name name
                     :activity (parse-long activity)})))))))

(defn get-session-path!
  "Get working directory of session's first pane"
  [session-name]
  (let [{:keys [out exit]} (tmux! "display-message" "-t" (str session-name ":0.0")
                                  "-p" "#{pane_current_path}")]
    (when (zero? exit)
      (str/trim out))))

(defn get-session-counts!
  "Get window and pane counts for session"
  [session-name]
  (let [windows (-> (tmux! "list-windows" "-t" session-name)
                    :out str/split-lines count)
        panes (-> (tmux! "list-panes" "-t" session-name "-a")
                  :out str/split-lines count)]
    {:windows windows :panes panes}))

;; =============================================================================
;; File System
;; =============================================================================

(defn ensure-dir! [path]
  (fs/create-dirs path))

(defn clone-repo! [url path]
  (let [result (p/shell {:out :inherit :err :inherit :continue true}
                        "git" "clone" url path)]
    (zero? (:exit result))))

(defn claude-project?! [path]
  (fs/directory? (str path "/.claude")))

;; =============================================================================
;; Terminal
;; =============================================================================

(defn print! [s]
  (println s))

(defn print-err! [s]
  (binding [*out* *err*]
    (println s)))

(defn exec-tmux-attach!
  "Replace current process with tmux attach (for interactive use)"
  [session-name]
  (p/exec "tmux" "attach" "-t" session-name))

;; =============================================================================
;; Dependency Checks
;; =============================================================================

(defn check-deps!
  "Check that required commands are available. Returns nil on success, error message on failure."
  []
  (cond
    (not (zero? (:exit (p/shell {:out :string :err :string :continue true} "which" "tmux"))))
    "tmux not found"

    (not (zero? (:exit (p/shell {:out :string :err :string :continue true} "which" "claude"))))
    "claude not found"

    :else nil))
