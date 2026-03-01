(ns registry
  "Loads all action namespace implementations.
   Core modules call (ensure-loaded!) rather than requiring action namespaces directly."
  (:require [actions.script]
            [actions.brew]
            [actions.mise]
            [actions.mas]
            [actions.bbin]
            [actions.npm]
            [actions.claude]
            [actions.osx]
            [actions.symlink]
            [actions.git]
            [actions.assert]))

(defn ensure-loaded!
  "Ensure all action namespaces are loaded. Safe to call multiple times."
  []
  ;; Requiring this namespace loads all action namespaces above.
  nil)
