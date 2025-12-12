(ns execute
  (:require [clojure.java.io :as io]
            [clojure.string :as str]
            [babashka.process :as process]
            [babashka.fs :as fs]
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

(defn- run-script [[script-name {:keys [path src]}]]
  (let [cmd (cond
              path ["bash" path]
              src  ["bash" "-c" src]
              :else (throw (ex-info "Script must have :path or :src" {:script script-name})))]
    (run-command (str "script - " (name script-name)) cmd)))

(defn- install-brew-package [[pkg {:keys [head]}]]
  (let [cmd (into ["brew" "install" (name pkg)] (when head ["--HEAD"]))]
    (run-command (str "brew - " (name pkg)) cmd)))

(defn- install-mise-tool [[tool {:keys [version global]}]]
  (let [tool (str (name tool) "@" version)]
    (if global
      (run-command (str "mise (use global) - " tool) ["mise" "use" "--global" tool])
      (run-command (str "mise - " tool) ["mise" "install" tool]))))

(defn- install-mas-package [[name id]]
  (let [cmd ["mas" "install" id]]
    (run-command (str "MAS - " name) cmd)))

(defn- install-bbin-package [[pkg opts]]
  (let [pkg-name (name pkg)
        package-arg (or (:url opts) pkg-name)
        as-name (if (and (:url opts)
                         (not (:as opts)))
                  pkg-name
                  (:as opts))
        base-cmd ["bbin" "install" package-arg]
        opts-flags (cond-> []
                     as-name             (into ["--as" as-name])
                     (:git/sha opts)     (into ["--git/sha" (:git/sha opts)])
                     (:git/tag opts)     (into ["--git/tag" (:git/tag opts)])
                     (:git/url opts)     (into ["--git/url" (:git/url opts)])
                     (:latest-sha opts)  (conj "--latest-sha")
                     (:local/root opts)  (into ["--local/root" (:local/root opts)])
                     (:main-opts opts)   (into ["--main-opts" (str (:main-opts opts))])
                     (:mvn/version opts) (into ["--mvn/version" (:mvn/version opts)])
                     (:ns-default opts)  (into ["--ns-default" (:ns-default opts)])
                     (:tool opts)        (conj "--tool"))
        cmd (into base-cmd opts-flags)]
    (run-command (str "bbin - " pkg-name) cmd)))

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

(defn unlink-symlinks
  "Removes stale symlinks. Takes a map of {target-path -> expected-source-path}.
   Only removes if the symlink exists and points to the expected location."
  [stale-symlinks]
  (when (seq stale-symlinks)
    (try
      (println " ┌─ Cleaning stale symlinks")
      (doseq [[target-str expected-source] stale-symlinks]
        (println " │ ┌─" target-str)
        (let [target-file (io/file (u/expand-tilde target-str))
              target-path (.toPath target-file)]
          ;; Use fs/exists? with :nofollow-links to check symlink itself, not its target
          (if-not (fs/exists? target-file {:nofollow-links true})
            (println " │ └─" (gray "skip (not found)"))
            (let [expected-source-path (.toPath (io/file expected-source))]
              (if-not (Files/isSymbolicLink target-path)
                (println " │ └─" (red "⚠ skip (not a symlink)"))
                (let [actual-link-target (Files/readSymbolicLink target-path)]
                  (if-not (= actual-link-target expected-source-path)
                    (println " │ └─" (red "⚠ skip (points elsewhere)"))
                    (do
                      (fs/delete target-file)
                      (println " │ └─" (green "✓ removed"))))))))))
      (catch Exception _
        (println " └─" (red "✗")))
      (println " └─" (green "✓")))))

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
          (do
            ;; Create parent directories if they don't exist
            (when-let [parent (.getParentFile target)]
              (.mkdirs parent))
            (let [cmd ["ln" "-s" (.getAbsolutePath source) (.getAbsolutePath target)]
                  {:keys [exit]} (exec! {:prefix " │ │"} cmd)]
              (println " │ └─" (if (zero? exit) (green "✓") (red "✗"))))))))
    (catch Exception _
      (println " └─" (red "✗")))
    (println " └─" (green "✓"))))



;; >> Execution

(defn run-basic-actions! [title f]
  (fn [data]
    (println "===" title "===")
    (run! f data)))

(def ^:private action-processors
  {:pkg/script   (run-basic-actions! "Running scripts"          run-script)
   :pkg/brew     (run-basic-actions! "Installing brew packages" install-brew-package)
   :pkg/mise     (run-basic-actions! "Installing mise packages" install-mise-tool)
   :pkg/mas      (run-basic-actions! "Installing MAS apps"      install-mas-package)
   :pkg/bbin     (run-basic-actions! "Installing bbin packages" install-bbin-package)
   :osx/defaults apply-defaults
   :fs/unlink    unlink-symlinks
   :fs/symlink   create-symlinks})

(defn execute-plan
  "Execute plan in dependency order.
   Takes {:plan merged-map :order [[type key] ...]}
   Batches contiguous same-type actions for grouped output."
  [{:keys [plan order]}]
  (doseq [batch (partition-by first order)]
    (let [action-type (ffirst batch)
          data (into {} (map (fn [[_ k]] [k (get-in plan [action-type k])]) batch))]
      (if-let [processor (action-processors action-type)]
        (processor data)
        (println "⚠️ Unknown action type:" action-type)))))
