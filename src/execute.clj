(ns execute 
  (:require [clojure.java.io :as io]
            [clojure.string :as str]
            [babashka.process :as process]
            [utils :as u])
  (:import [java.nio.file Files Paths]))

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
     ;; Wait for completion
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


;; >> Processors

(defn- install-brew-package [[pkg {:keys [head]}]]
  (let [cmd (into ["brew" "install" (name pkg)] (when head ["--HEAD"]))]
    (run-command (str "brew - " (name pkg)) cmd)))

(defn- install-mise-tool [[tool {:keys [version global]}]]
  (let [tool (str (name tool) "@" version)
        cmd ["mise" "install" tool]]
    (run-command (str "mise - " tool) cmd)
    (when global
      (let [cmd ["mise" "use" "--global" tool]]
        (run-command (str "mise (use global) - " tool) cmd)))))

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

(defn apply-defaults [defaults]
  (try
    (println " ┌─ Setting OSX Defaults")
    (doseq [[domain settings] defaults]
      (println " ├─┬──" domain)
      (doseq [[idx [key value]] (zipmap (range) settings)]
        (let [last? (= idx (dec (count settings)))
              type-flag (->defaults-type value)
              cmd ["defaults" "write" domain (name key) type-flag value]
              {:keys [exit]} (exec! {:prefix " │ │"} cmd)]
          (println (if last? " │ └─" " │ ├─")
                   key value (if (zero? exit) (green "✓") (red "✗"))))))
    (catch Exception _
      (println " └─" (red "✗")))
    (println " └─" (green "✓"))))

(defn create-symlinks [links]
  (try
    (println " ┌─ Creating Symlinks")
    (doseq [[target source] links]
      (println " │ ┌─" target)
      (let [target (io/file (u/expand-tilde target))
            source (io/file source)]
        (if (.exists target)
          (let [target-path (Paths/get (.toURI target))
                source-path (Paths/get (.toURI source))]
            (if (and (Files/isSymbolicLink target-path)
                     (= (Files/readSymbolicLink target-path)
                        source-path))
              (println " │ └─" (green "✓"))
              (println " │ └─" (red "✗"))))
          (let [cmd ["ln" "-s" (.getAbsolutePath source) (.getAbsolutePath target)]
                {:keys [exit]} (exec! {:prefix " │ │"} cmd)]
            (println " │ └─" (if (zero? exit) (green "✓") (red "✗")))))))
    (catch Exception _
      (println " └─" (red "✗")))
    (println " └─" (green "✓"))))



;; >> Execution

(defn run-basic-actions! [title f]
  (fn [data]
    (println "===" title "===")
    (run! f data)))

(def ^:private action-processors
  {:pkg/brew     (run-basic-actions! "Installing brew packages" install-brew-package)
   :pkg/mise     (run-basic-actions! "Installing mise packages" install-mise-tool)
   :pkg/mas      (run-basic-actions! "Installing MAS apps"      install-mas-package)
   :osx/defaults apply-defaults
   :fs/symlink   create-symlinks})

(defn- process-action [[action-type data]]
  (if-let [processor (action-processors action-type)]
    (processor data)
    (println "⚠️ Unknown action type:" action-type)))

(defn- execute-step [actions]
  (run! process-action actions))

(defn execute-plan [steps]
  (run! execute-step steps))
