(ns cc.main
  (:require [babashka.process :as p]
            [clojure.string :as str]
            [babashka.fs :as fs]))

(defn git-root
  "Returns the git repo root, or nil if not in a git repo."
  []
  (try
    (let [result (p/shell {:out :string :err :string} "git rev-parse --show-toplevel")]
      (when (zero? (:exit result))
        (str/trim (:out result))))
    (catch Exception _ nil)))

(defn git-worktree-name
  "If in a worktree, returns the worktree branch/directory name, else nil."
  []
  (try
    (let [git-dir (-> (p/shell {:out :string :err :string} "git rev-parse --git-dir")
                      :out str/trim)]
      (when (str/includes? git-dir "/worktrees/")
        (last (str/split git-dir #"/worktrees/"))))
    (catch Exception _ nil)))

(defn git-main-root
  "Returns the main repo root, even when inside a worktree."
  []
  (try
    (let [common-dir (-> (p/shell {:out :string :err :string}
                                  "git" "rev-parse" "--path-format=absolute" "--git-common-dir")
                         :out str/trim)]
      (str (fs/parent common-dir)))
    (catch Exception _ nil)))

(defn session-name
  "Derive a tmux session name from the current directory.
   - Git repo: basename of main repo root (+ ~worktree if in a worktree)
   - Not git: sanitized full path"
  []
  (let [sanitize #(-> % (str/replace #"^/" "") (str/replace #"[\.:]" "_"))
        cwd (System/getProperty "user.dir")]
    (if-let [root (git-main-root)]
      (let [base (fs/file-name root)
            wt (git-worktree-name)]
        (cond-> (str base)
          wt (str "~" wt)))
      (sanitize cwd))))

(defn tmux-config-path []
  (let [candidates [(str (fs/home) "/dotfiles/tools/cc/tmux.conf")]]
    (first (filter fs/exists? candidates))))

(defn session-exists? [name]
  (zero? (:exit (p/shell {:out :string :err :string :continue true}
                         "tmux" "has-session" "-t" name))))

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

(defn build-claude-args
  "Build claude command args, injecting --session-id if no --resume present.
   Returns [claude-args session-id]."
  [args]
  (let [resume-id (extract-resume-id args)]
    (if resume-id
      ;; --resume already present, use that as the session id to print later
      [(concat ["claude" "--dangerously-skip-permissions"] args) resume-id]
      ;; No --resume, generate a UUID and inject --session-id
      (let [uuid (str (java.util.UUID/randomUUID))]
        [(concat ["claude" "--dangerously-skip-permissions" "--session-id" uuid] args) uuid]))))

(defn create [args]
  (let [name (session-name)
        conf (tmux-config-path)
        [claude-args session-id] (build-claude-args args)
        claude-cmd (str/join " " claude-args)]
    (when-not conf
      (binding [*out* *err*]
        (println "Warning: tmux.conf not found, using defaults")))
    (if (session-exists? name)
      (do
        (println (str "Attaching to existing session: " name))
        (p/exec "tmux" "attach-session" "-t" name))
      (do
        (p/shell (cond-> ["tmux"]
                   conf (into ["-f" conf])
                   true (into ["new-session" "-s" name claude-cmd])))
        ;; tmux has exited — back in the caller's terminal
        (println)
        (println (str "To resume: cc --resume " session-id))))))

(defn -main [& args]
  (if (= (first args) "ls")
    (ls)
    (create args)))
