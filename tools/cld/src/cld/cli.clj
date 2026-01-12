(ns cld.cli
  "Pure argument parsing for cld CLI."
  (:require [clojure.string :as str]))

(defn parse-args
  "Parse command line arguments into a command map.

   Returns:
   {:command   :start|:list|:kill|:rename|:select|:help|:error
    :project   string or nil
    :target    string (for :kill)
    :old       string (for :rename)
    :new       string (for :rename)
    :filter    string (for :list)
    :opts      {:session-name string, :windows int}
    :message   string (for :error)}

   Examples:
   []                    -> {:command :start :project nil}
   [\"myapp\"]           -> {:command :start :project \"myapp\"}
   [\"myapp\" \"-n\" \"test\"] -> {:command :start :project \"myapp\" :opts {:session-name \"test\"}}
   [\"-l\"]              -> {:command :list}
   [\"-k\" \"foo\"]       -> {:command :kill :target \"foo\"}
   [\"-r\" \"old\" \"new\"] -> {:command :rename :old \"old\" :new \"new\"}
   [\"-s\"]              -> {:command :select}
   [\"-h\"]              -> {:command :help}"
  [args]
  (loop [args (vec args)
         result {:command :start :project nil :opts {}}]
    (if (empty? args)
      result
      (let [[arg & rest-args] args]
        (cond
          ;; List sessions
          (#{"-l" "--list" "ls"} arg)
          {:command :list :filter (first rest-args)}

          ;; Kill session
          (#{"-k" "--kill" "kill"} arg)
          (if-let [target (first rest-args)]
            {:command :kill :target target}
            {:command :error :message "Usage: cld -k <session>"})

          ;; Rename session
          (#{"-r" "--rename"} arg)
          (let [[old new] rest-args]
            (if (and old new)
              {:command :rename :old old :new new}
              {:command :error :message "Usage: cld -r <old> <new>"}))

          ;; Select interactively
          (#{"-s" "--select"} arg)
          {:command :select}

          ;; Help
          (#{"-h" "--help" "help"} arg)
          {:command :help}

          ;; Session name option
          (#{"-n" "--name"} arg)
          (if-let [name (first rest-args)]
            (recur (vec (rest rest-args))
                   (assoc-in result [:opts :session-name] name))
            {:command :error :message "Usage: cld -n <session-name>"})

          ;; Windows option
          (#{"-w" "--windows"} arg)
          (if-let [n (some-> (first rest-args) parse-long)]
            (recur (vec (rest rest-args))
                   (assoc-in result [:opts :windows] n))
            {:command :error :message "Usage: cld -w <number>"})

          ;; Unknown flag
          (str/starts-with? arg "-")
          {:command :error :message (str "Unknown option: " arg)}

          ;; Positional = project
          :else
          (recur (vec rest-args)
                 (assoc result :project arg)))))))
