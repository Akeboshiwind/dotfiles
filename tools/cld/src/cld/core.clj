(ns cld.core
  "Pure functions for cld - no side effects."
  (:require [clojure.string :as str]))

;; =============================================================================
;; Constants
;; =============================================================================

(def session-prefix "claude")

;; =============================================================================
;; Colors
;; =============================================================================

(def colors
  {:red     "\033[0;31m"
   :green   "\033[0;32m"
   :blue    "\033[0;34m"
   :yellow  "\033[0;33m"
   :cyan    "\033[0;36m"
   :magenta "\033[0;35m"
   :dim     "\033[2m"
   :reset   "\033[0m"})

(defn colorize [color s]
  (str (colors color) s (:reset colors)))

;; =============================================================================
;; Name Handling
;; =============================================================================

(defn sanitize-name
  "Make a string safe for tmux session names.
   Replaces non-alphanumeric chars (except -) with dashes.

   Examples:
   \"my_project\" -> \"my-project\"
   \"foo/bar\" -> \"foo-bar\"
   \"already-valid\" -> \"already-valid\""
  [s]
  (-> s
      (str/replace #"[^a-zA-Z0-9-]" "-")
      (str/replace #"-+" "-")
      (str/replace #"^-|-$" "")))

(defn make-session-name
  "Build full session name from project and optional suffix.

   Examples:
   {:project \"myapp\"} -> \"claude-myapp\"
   {:project \"myapp\" :suffix \"testing\"} -> \"claude-myapp-testing\"
   {:project \"my_app\" :suffix \"feature/auth\"} -> \"claude-my-app-feature-auth\""
  [{:keys [project suffix]}]
  (let [base (str session-prefix "-" (sanitize-name project))]
    (if suffix
      (str base "-" (sanitize-name suffix))
      base)))

(defn parse-session-name
  "Extract project and suffix from a session name.

   Examples:
   \"claude-myapp\" -> {:project \"myapp\" :suffix nil}
   \"claude-myapp-testing\" -> {:project \"myapp\" :suffix \"testing\"}
   \"not-claude-session\" -> nil"
  [session-name]
  (when (str/starts-with? session-name (str session-prefix "-"))
    (let [rest (subs session-name (inc (count session-prefix)))
          parts (str/split rest #"-" 2)]
      {:project (first parts)
       :suffix (second parts)})))

(defn ensure-prefix
  "Add claude- prefix if not present."
  [name]
  (if (str/starts-with? name (str session-prefix "-"))
    name
    (str session-prefix "-" name)))

;; =============================================================================
;; Project Resolution
;; =============================================================================

(defn resolve-project-input
  "Categorize what kind of project input this is. Pure function.

   Returns {:type :cwd|:github|:absolute-path|:relative-path|:project-name
            ...type-specific keys...}

   Examples:
   nil -> {:type :cwd}
   \"https://github.com/user/repo\" -> {:type :github :url ... :repo \"repo\"}
   \"https://github.com/user/repo.git\" -> {:type :github :url ... :repo \"repo\"}
   \"/absolute/path\" -> {:type :absolute-path :path \"/absolute/path\"}
   \"./relative\" -> {:type :relative-path :path \"./relative\"}
   \"myproject\" -> {:type :project-name :name \"myproject\"}"
  [input]
  (cond
    (nil? input)
    {:type :cwd}

    (str/starts-with? input "https://github.com/")
    (let [;; Extract repo name from URL
          parts (str/split input #"/")
          repo (-> (last parts)
                   (str/replace #"\.git$" ""))]
      {:type :github :url input :repo repo})

    (str/starts-with? input "/")
    {:type :absolute-path :path input}

    (or (str/starts-with? input "./")
        (str/starts-with? input "../"))
    {:type :relative-path :path input}

    :else
    {:type :project-name :name input}))

(defn build-project-plan
  "Given resolved input and filesystem state, determine what to do.

   Arguments:
   - resolved: output from resolve-project-input
   - context: {:cwd string
               :projects-dir string
               :path-exists? fn}  ; pure predicate, injected

   Returns:
   {:name string        ; sanitized project name
    :path string        ; absolute path to project
    :action :use-existing|:create-dir|:clone-repo
    :clone-url string}  ; only if action is :clone-repo"
  [resolved {:keys [cwd projects-dir path-exists?]}]
  (case (:type resolved)
    :cwd
    (let [name (last (str/split cwd #"/"))]
      {:name name :path cwd :action :use-existing})

    :github
    (let [{:keys [url repo]} resolved
          path (str projects-dir "/" repo)]
      (if (path-exists? path)
        {:name repo :path path :action :use-existing}
        {:name repo :path path :action :clone-repo :clone-url url}))

    :absolute-path
    (let [path (:path resolved)
          name (last (str/split path #"/"))]
      {:name name :path path :action :use-existing})

    :relative-path
    (let [rel-path (:path resolved)
          ;; Simple path join - in real impl would normalize
          path (if (str/starts-with? rel-path "./")
                 (str cwd "/" (subs rel-path 2))
                 (str cwd "/" rel-path))
          name (last (str/split path #"/"))]
      {:name name :path path :action :use-existing})

    :project-name
    (let [{:keys [name]} resolved
          path (str projects-dir "/" name)]
      (if (path-exists? path)
        {:name name :path path :action :use-existing}
        {:name name :path path :action :create-dir}))))

;; =============================================================================
;; Time Formatting
;; =============================================================================

(defn format-time-ago
  "Format seconds-since-epoch as human readable relative time.
   Takes current time as parameter for testability.

   Arguments:
   - activity-epoch: unix timestamp of activity
   - now-epoch: current unix timestamp

   Examples (assuming now = 1000):
   activity=970, now=1000 -> \"30s ago\"
   activity=940, now=1000 -> \"1m ago\"
   activity=400, now=1000 -> \"10m ago\"
   activity=0, now=3600 -> \"1h ago\"
   activity=0, now=86400 -> \"1d ago\""
  [activity-epoch now-epoch]
  (let [diff (- now-epoch activity-epoch)]
    (cond
      (< diff 60)    (str diff "s ago")
      (< diff 3600)  (str (quot diff 60) "m ago")
      (< diff 86400) (str (quot diff 3600) "h ago")
      :else          (str (quot diff 86400) "d ago"))))

;; =============================================================================
;; Output Formatting
;; =============================================================================

(defn format-ok [msg]
  (str (colorize :green "✓") " " msg))

(defn format-error [msg]
  (str (colorize :red "✗") " " msg))

(defn format-info [msg]
  (str (colorize :blue "→") " " msg))

(defn format-warn [msg]
  (str (colorize :yellow "⚠") " " msg))

(defn format-dim [msg]
  (colorize :dim msg))

(defn format-session
  "Format a single session for display.

   Input map:
   {:name \"claude-myapp\"
    :path \"/home/user/projects/myapp\"
    :windows 2
    :panes 3
    :activity-ago \"5m ago\"
    :is-claude-project? true}

   Returns multi-line string."
  [{:keys [name path windows panes activity-ago is-claude-project?]}]
  (str "\n" (colorize :green "●") " " (colorize :magenta name) "\n"
       (when path
         (str "  " (format-dim "Path:") " " path "\n"
              (when is-claude-project?
                (str "  " (format-dim "Type:") " " (colorize :cyan "Claude Project") "\n"))))
       "  " (format-dim "Windows:") " " windows
       " " (format-dim "│ Panes:") " " panes
       (when activity-ago
         (str " " (format-dim "│ Active:") " " activity-ago))))

(defn format-session-list
  "Format multiple sessions for list display."
  [sessions]
  (if (empty? sessions)
    (str "No active sessions\n\n"
         "Start one:\n"
         "  cld [project]\n"
         "  cld [project] -n [name]  # Named session")
    (str (colorize :blue "Active Claude Sessions") "\n"
         "────────────────────────────────────────────"
         (str/join "" (map format-session sessions))
         "\n\n" (format-dim "Tip: Use 'cld -r <old> <new>' to rename sessions"))))

(defn format-no-sessions []
  (str "No active sessions\n\n"
       "Start one:\n"
       "  cld [project]\n"
       "  cld [project] -n [name]  # Named session"))

(defn format-help []
  "cld - Claude tmux session manager

USAGE:
    cld [project]              Start/attach session
    cld [project] -n [name]    Named session for project
    cld -l [filter]            List sessions (with details)
    cld -k <name>              Kill session
    cld -r <old> <new>         Rename session
    cld -s                     Select session interactively
    cld -h                     Show help

OPTIONS:
    -n, --name NAME      Create named session (e.g., \"feature-x\")
    -w, --windows N      Create N windows (default: 1)

PROJECT can be:
    • Path to directory
    • GitHub URL
    • Project name
    • Empty (current dir)

EXAMPLES:
    cld                              # Current directory
    cld myapp                        # Project in ~/projects/
    cld myapp -n testing             # Named session \"claude-myapp-testing\"
    cld ~/work/api -n bugfix         # Multiple sessions for same project
    cld -l                           # List with activity & context size
    cld -r claude-api claude-api-v2  # Rename session

TIPS:
    • Detach: Ctrl+b d
    • Switch windows: Ctrl+b [0-9]
    • Sessions persist across SSH")

;; =============================================================================
;; Command Building
;; =============================================================================

(defn build-tmux-args
  "Build tmux command arguments. Returns vector of strings.

   Examples:
   {:op :new-session :name \"claude-foo\" :path \"/tmp\" :cmd \"claude\"}
   -> [\"new-session\" \"-d\" \"-s\" \"claude-foo\" \"-c\" \"/tmp\" \"claude\"]

   {:op :attach :name \"claude-foo\"}
   -> [\"attach\" \"-t\" \"claude-foo\"]

   {:op :kill-session :name \"claude-foo\"}
   -> [\"kill-session\" \"-t\" \"claude-foo\"]

   {:op :has-session :name \"claude-foo\"}
   -> [\"has-session\" \"-t\" \"claude-foo\"]

   {:op :list-sessions :format \"#{session_name}|#{session_activity}\"}
   -> [\"ls\" \"-F\" \"#{session_name}|#{session_activity}\"]"
  [{:keys [op name path cmd format]}]
  (case op
    :new-session
    (cond-> ["new-session" "-d" "-s" name]
      path (into ["-c" path])
      cmd  (conj cmd))

    :attach
    ["attach" "-t" name]

    :kill-session
    ["kill-session" "-t" name]

    :has-session
    ["has-session" "-t" name]

    :list-sessions
    (if format
      ["ls" "-F" format]
      ["ls"])

    :rename-session
    ["rename-session" "-t" (:old-name path) name]

    :new-window
    (cond-> ["new-window" "-t" name]
      path (into ["-c" path])
      cmd  (conj cmd))))
