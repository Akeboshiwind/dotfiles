(ns execute)


(def ^:dynamic *dry-run* false)

;; >> Processors

(defn- install-brew-package [[pkg {:keys [head]}]]
  (when *dry-run*
    (println (str "brew install " (name pkg) (when head " --HEAD")))))

(defn- install-mise-tool [[tool {:keys [version]}]]
  (when *dry-run*
    (println "mise install" (str (name tool) "@" version))))

(defn- install-mas-package [[name id]]
  (when *dry-run*
    (println "mas install" id "#" name)))

; See `man defaults`, basically:
; No flag = -string
; Flags: -string, -int, -float, -bool, -date, -array el el el, -array-add (append), -dict k1 v2 k2 v2, -dict-add
(defn- ->defaults-type [value]
  ; NOTE: For some reason `case` wouldn't work here? May need to update babashka
  (if (= java.lang.Boolean (type value))
    "-bool"
    "-string"))

(defn- apply-default [[domain settings]]
  (run! (fn [[key value]]
          (let [type-flag (->defaults-type value)]
            (when *dry-run*
              (println "defaults write" domain (name key) type-flag value))))
        settings))

(defn- create-symlink [[target source]]
  (when *dry-run*
    (println "ln -s" source target)))



;; >> Execution

(defn run-basic-actions! [title f]
  (fn [data]
    (println "===" title "===")
    (run! f data)))

(def ^:private action-processors
  {:pkg/brew     (run-basic-actions! "Installing brew packages" install-brew-package)
   :pkg/mise     (run-basic-actions! "Installing mise packages" install-mise-tool)
   :pkg/mas      (run-basic-actions! "Installing MAS apps"      install-mas-package)
   :osx/defaults (run-basic-actions! "Setting OSX defaults"     apply-default)
   :fs/symlink   (run-basic-actions! "Creating symlinks"        create-symlink)})

(defn- process-action [[action-type data]]
  (if-let [processor (action-processors action-type)]
    (processor data)
    (println "⚠️ Unknown action type:" action-type)))

(defn- execute-step [actions]
  (run! process-action actions))

(defn execute-plan [steps]
  (run! execute-step steps))
