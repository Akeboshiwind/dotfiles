(ns execute
  (:require [clojure.java.io :as io]
            [clojure.string :as str]
            [babashka.process :as process]
            [actions.core :as a]
            ;; Load all action implementations
            [actions.script]
            [actions.brew]
            [actions.mise]
            [actions.mas]
            [actions.bbin]
            [actions.npm]
            [actions.claude]
            [actions.osx]
            [actions.symlink]))

(def ^:dynamic *dry-run* false)

(def GRAY "\033[90m")
(def GREEN "\033[32m")
(def RED "\033[31m")
(def RESET "\033[0m")

(def gray #(str GRAY % RESET))
(def green #(str GREEN % RESET))
(def red #(str RED % RESET))

(defn- prefix-print
  ([stream] (prefix-print " │" stream))
  ([prefix stream]
   (with-open [rdr (io/reader stream)]
     (doseq [line (line-seq rdr)]
       (println prefix (gray line))))))

(defn exec!
  ([args]
   (exec! {} args))
  ([{:keys [prefix] :or {prefix " │"}}
    args]
   (let [proc (process/process args)
         out-future (future (prefix-print prefix (:out proc)))
         err-future (future (prefix-print prefix (:err proc)))]
     @out-future
     @err-future
     @proc)))

(defn run-command'
  "Runs the given command, streaming the output, prefixing lines"
  [label args]
  (try
    (println " ┌─" label)
    (let [{:keys [exit]} (exec! args)]
      (println " └─" (if (zero? exit) (green "✓") (red "✗")))
      (zero? exit))
    (catch Exception _
      (println " └─" (red "✗"))
      false)))

(defn dry-run-command [_label args]
  (println (str/join " " args))
  true)

(defn run-command [label args]
  (let [run (if *dry-run* dry-run-command run-command')]
    (run label args)))

;; >> Execution context passed to actions

(defn- make-ctx []
  {:run-command run-command
   :exec! exec!})

;; >> Execution

(defn- action-title [action-type]
  (case action-type
    :pkg/script "Running scripts"
    :pkg/brew "Installing brew packages"
    :pkg/mise "Installing mise packages"
    :pkg/mas "Installing MAS apps"
    :pkg/bbin "Installing bbin packages"
    :pkg/npm "Installing npm packages"
    :claude/marketplace "Adding Claude marketplaces"
    :claude/plugin "Installing Claude plugins"
    :claude/mcp "Adding Claude MCP servers"
    :osx/defaults nil  ; handles own title
    :fs/unlink nil     ; handles own title
    :fs/symlink nil    ; handles own title
    (str "Processing " (name action-type))))

(defn execute-plan
  "Execute plan in dependency order.
   Takes {:plan merged-map :order [[type key] ...]}
   Batches contiguous same-type actions for grouped output."
  [{:keys [plan order]}]
  (let [ctx (make-ctx)]
    (doseq [batch (partition-by first order)]
      (let [action-type (ffirst batch)
            data (into {} (map (fn [[_ k]] [k (get-in plan [action-type k])]) batch))]
        (if (a/supports? action-type)
          (do
            (when-let [title (action-title action-type)]
              (println "===" title "==="))
            (a/install! action-type data ctx))
          (println "Warning: Unknown action type:" action-type))))))
