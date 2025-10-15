(ns execute 
  (:require [clojure.java.io :as io]
            [clojure.string :as str]
            [babashka.process :as process]))

(def ^:dynamic *dry-run* false)

(def GRAY "\033[90m")
(def RESET "\033[0m")

(defn- prefix-print [stream]
  (with-open [rdr (io/reader stream)]
    (doseq [line (line-seq rdr)]
      (println (str " │ " GRAY line RESET)))))

(defn run-command'
  "Runs the given command, streaming the output, prefixing lines"
  [label args]
  (try
    (println " ┌─" label)
    (let [proc (process/process args)
          out-future (future (prefix-print (:out proc)))
          err-future (future (prefix-print (:err proc)))]
      @out-future
      @err-future
      ;; Wait for completion
      (let [{:keys [exit]} @proc]
        (println " └─" (if (zero? exit) "✓" "✗"))
        (zero? exit)))
    (catch Exception _
      false)))

(defn dry-run-command [_label args]
  (println (str/join " " args))
  true)

(defn run-command [label args]
  (let [run (if *dry-run* dry-run-command run-command')]
    (run label args)))


;; >> Processors

(defn- install-brew-package [[pkg {:keys [head]}]]
  (let [cmd ["brew" "install" (name pkg) (when head " --HEAD")]]
    (run-command (str "brew -" pkg) cmd)))

(defn- install-mise-tool [[tool {:keys [version]}]]
  (let [cmd ["mise" "install" (str (name tool) "@" version)]]
    (run-command (str "mise -" tool) cmd)))

(defn- install-mas-package [[name id]]
  (let [cmd ["mas" "install" id]]
    (run-command (str "MAS -" name) cmd)))

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
