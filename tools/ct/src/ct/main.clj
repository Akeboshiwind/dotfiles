(ns ct.main
  (:require [babashka.process :as p]
            [babashka.fs :as fs]
            [clojure.string :as str]))

(defn git-repo-name
  "Returns the basename of the git repo root, or nil if not in a git repo."
  []
  (try
    (let [result (p/shell {:out :string :err :string} "git rev-parse --show-toplevel")]
      (when (zero? (:exit result))
        (str (fs/file-name (str/trim (:out result))))))
    (catch Exception _ nil)))

(defn tmux-config-path []
  (let [path (str (fs/home) "/dotfiles/tools/ct/tmux.conf")]
    (when (fs/exists? path) path)))

(defn tmux-sessions
  "Returns a list of tmux session lines, or nil if tmux server isn't running."
  []
  (try
    (let [result (p/shell {:out :string :err :string :continue true}
                          "tmux" "list-sessions" "-F"
                          "#{session_name}\t#{session_attached}\t#{session_activity}")]
      (when (zero? (:exit result))
        (str/split-lines (str/trim (:out result)))))
    (catch Exception _ nil)))

(defn format-session-line [line]
  (let [[name attached _activity] (str/split line #"\t")]
    (str name (when (= attached "1") " (attached)"))))

(defn ls []
  (if-let [sessions (tmux-sessions)]
    (let [formatted (str/join "\n" (map format-session-line sessions))
          result (p/shell {:in formatted :out :string :err :inherit :continue true}
                          "fzf" "--ansi" "--prompt" "session> " "--header" "Select a session to attach")]
      (when (zero? (:exit result))
        (let [selected (-> (:out result) str/trim (str/replace #" \(attached\)$" ""))]
          (p/exec "tmux" "attach-session" "-t" selected))))
    (do
      (println "No tmux sessions running.")
      (System/exit 0))))

(defn extract-resume-id
  "If args contain --resume, return that value. Otherwise nil."
  [args]
  (let [args-vec (vec args)]
    (some (fn [i]
            (when (= (nth args-vec i) "--resume")
              (nth args-vec (inc i) nil)))
          (range (dec (count args-vec))))))

(defn claude-cmd
  "Build the claude command string. Generates a session ID if none provided.
   Returns [cmd-string session-id]."
  [args]
  (let [resume-id (extract-resume-id args)
        session-id (or resume-id (str (java.util.UUID/randomUUID)))
        all-args (cond-> (vec args)
                   (not resume-id) (into ["--session-id" session-id]))]
    [(str/join " " (into ["claude" "--dangerously-skip-permissions"] all-args))
     session-id]))

(defn run-in-tmux
  "Run a command string in a new tmux session."
  [session-name cmd]
  (let [conf (tmux-config-path)]
    (p/shell (cond-> ["tmux"]
               conf (into ["-f" conf])
               true (into ["new-session" "-s" session-name cmd])))))

(defn session
  "Start claude in a tmux session named after the git repo."
  [resume-hint args]
  (let [base (or (git-repo-name) "ct")
        [cmd session-id] (claude-cmd args)
        name (str base "-" session-id)]
    (run-in-tmux name cmd)
    (println)
    (println (str "To resume: " resume-hint " --resume " session-id))))

(defn task
  "Start claude in a worktree, letting claude manage tmux via --tmux."
  [task-name args]
  (let [resume-id (extract-resume-id args)
        session-id (or resume-id (str (java.util.UUID/randomUUID)))
        all-args (cond-> ["--worktree" task-name "--tmux" "--dangerously-skip-permissions"]
                   (not resume-id) (into ["--session-id" session-id])
                   true (into (vec args)))]
    (apply p/shell "claude" all-args)
    (println)
    (println (str "To resume: ct task " task-name " --resume " session-id))))

(defn help []
  (println "Usage: ct [command] [args...]

Commands:
  ct [args]                 Start claude in a tmux session
  ct task <name> [args]     Start claude in a git worktree + tmux
  ct ls                     Attach to an existing tmux session
  ct --help                 Show this help

All other args are passed through to claude."))

(defn -main [& args]
  (case (first args)
    ("--help" "-h") (help)
    "ls"   (ls)
    "task" (if (< (count args) 2)
             (binding [*out* *err*]
               (println "Usage: ct task <name> [args...]")
               (System/exit 1))
             (task (second args) (drop 2 args)))
    (session "ct" args)))
