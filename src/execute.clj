(ns execute
  (:require [actions.core :as a]
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
  (doseq [batch (partition-by first order)]
    (let [action-type (ffirst batch)
          data (into {} (map (fn [[_ k]] [k (get-in plan [action-type k])]) batch))]
      (if (a/supports? action-type)
        (do
          (when-let [title (action-title action-type)]
            (println "===" title "==="))
          (a/install! action-type data))
        (println "Warning: Unknown action type:" action-type)))))
