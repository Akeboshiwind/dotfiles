(ns rnvim.main
  (:require [babashka.process :as p]
            [babashka.fs :as fs]
            [clojure.string :as str]))

;; Constants
(def nvim-port 6666)
(def remote-nvim-bin "nvim-linux-x86_64/bin/nvim")
(def remote-config-dir ".config/nvim")
(def nvim-tarball-url "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz")

;; Helpers

(defn sprite-exec
  "Execute command on sprite, returns exit code"
  [sprite & args]
  (let [cmd (into ["sprite" "-s" sprite "exec" "bash" "-c"]
                  [(str/join " " args)])]
    (-> (p/process cmd {:inherit true})
        deref
        :exit)))

(defn sprite-exec-silent
  "Execute command on sprite, returns {:exit :out :err}"
  [sprite & args]
  (let [cmd (into ["sprite" "-s" sprite "exec" "bash" "-c"]
                  [(str/join " " args)])]
    (-> (p/process cmd {:out :string :err :string})
        deref
        (select-keys [:exit :out :err]))))

(defn tar-nvim-config
  "Create tarball of nvim config, returns path"
  []
  (let [config-dir (str (fs/home) "/.config/nvim")
        tarball (str (fs/create-temp-file {:prefix "nvim-config-" :suffix ".tar.gz"}))]
    (p/shell {:dir (str (fs/home) "/.config")} "tar" "chzf" tarball "nvim")
    tarball))

(defn upload-and-extract
  "Upload tarball to sprite and extract to ~/.config/nvim"
  [sprite tarball]
  (println "Uploading nvim config to sprite...")
  (let [remote-tar "/tmp/nvim-config.tar.gz"
        cmd ["sprite" "-s" sprite "exec"
             "-file" (str tarball ":" remote-tar)
             "bash" "-c"
             (str "mkdir -p ~/.config && cd ~/.config && tar xzf " remote-tar " && rm " remote-tar)]]
    (-> (p/process cmd {:inherit true})
        deref
        :exit)))

(defn nvim-installed?
  "Check if nvim is installed on sprite"
  [sprite]
  (let [{:keys [exit]} (sprite-exec-silent sprite "test -x" remote-nvim-bin)]
    (zero? exit)))

(defn ensure-nvim-installed
  "Download and install nvim on sprite if not present"
  [sprite]
  (when-not (nvim-installed? sprite)
    (println "Installing nvim on sprite...")
    (sprite-exec sprite
                 "curl -LO" nvim-tarball-url
                 "&& tar xzf nvim-linux-x86_64.tar.gz"
                 "&& rm nvim-linux-x86_64.tar.gz")))

(defn start-remote-nvim
  "Start headless nvim on sprite, returns PID"
  [sprite]
  (println "Starting remote nvim...")
  (let [{:keys [out]} (sprite-exec-silent sprite
                                          "nohup" remote-nvim-bin
                                          "--headless"
                                          (str "--listen 0.0.0.0:" nvim-port)
                                          "> /tmp/nvim.log 2>&1 &"
                                          "echo $!")]
    (str/trim out)))

(defn kill-remote-nvim
  "Kill nvim process on sprite"
  [sprite]
  (println "Stopping remote nvim...")
  (sprite-exec-silent sprite "pkill -f 'nvim.*--headless' || true"))

(defn start-proxy
  "Start sprite proxy, returns process"
  [sprite]
  (println "Starting port proxy...")
  (let [proc (p/process ["sprite" "-s" sprite "proxy" (str nvim-port)]
                        {:inherit true})]
    (Thread/sleep 1000) ; Give proxy time to establish
    proc))

(defn connect-local-nvim
  "Connect local nvim to remote server, blocks until exit"
  []
  (println "Connecting to remote nvim...")
  (println "")
  (-> (p/process ["nvim" "--server" (str "localhost:" nvim-port) "--remote-ui"]
                 {:inherit true})
      deref))

;; Resource management

(defn with-temp-tarball
  "Execute f with tarball path, cleanup on exit"
  [f]
  (let [tarball (tar-nvim-config)]
    (try
      (f tarball)
      (finally
        (fs/delete-if-exists tarball)))))

(defn with-remote-nvim
  "Execute f with remote nvim running, cleanup on exit"
  [sprite f]
  (let [pid (start-remote-nvim sprite)]
    (try
      (Thread/sleep 500) ; Give nvim time to start
      (f pid)
      (finally
        (kill-remote-nvim sprite)))))

(defn with-proxy
  "Execute f with proxy running, cleanup on exit"
  [sprite f]
  (let [proc (start-proxy sprite)]
    (try
      (f proc)
      (finally
        (p/destroy proc)))))

;; Commands

(defn sprite-cmd
  "Connect to sprite with remote nvim"
  [sprite-name]
  (with-temp-tarball
    (fn [tarball]
      (upload-and-extract sprite-name tarball)
      (ensure-nvim-installed sprite-name)
      (with-remote-nvim sprite-name
        (fn [_pid]
          (with-proxy sprite-name
            (fn [_proc]
              (connect-local-nvim))))))))

(defn -main [& args]
  (let [[cmd sprite-name] args]
    (case cmd
      "sprite" (if sprite-name
                 (sprite-cmd sprite-name)
                 (do (println "Usage: rnvim sprite <name>")
                     (System/exit 1)))
      (do (println "Usage: rnvim sprite <name>")
          (println "")
          (println "Commands:")
          (println "  sprite <name>  Connect to a sprite with remote nvim")
          (System/exit (if (nil? cmd) 0 1))))))
