(ns actions.brew
  (:require [actions :as a]
            [babashka.process :as process]
            [cheshire.core :as json]
            [clojure.set :as set]
            [clojure.string :as str]
            [display :as d]
            [outcome :as o]
            [utils :as u]))

(defmethod a/requires :pkg/brew [_] :pkg/brew)
(defmethod a/requires :brew/service [_] :brew/service)

(defn installed-set
  "Return #{name ...} of installed formulae or casks."
  [kind]
  (let [flag (if (= kind :cask) "--cask" "--formula")]
    (d/with-spinner (str "Listing Homebrew " (if (= kind :cask) "casks" "formulae"))
      (->> (process/shell {:out :string :err :string} "brew" "list" flag "-1")
           :out
           str/split-lines
           (remove str/blank?)
           set))))

(defn outdated-map
  "Return {name {:installed v1 :current v2}} from brew outdated."
  []
  (let [raw (-> (d/with-spinner "Checking for outdated Homebrew packages"
                  (process/shell {:out :string :err :string} "brew" "outdated" "--json=v2"))
                :out
                (json/parse-string true))
        parse (fn [items]
                (into {}
                  (map (fn [{:keys [name installed_versions current_version]}]
                         [name {:installed (first installed_versions)
                                :current current_version}]))
                  items))]
    (merge (parse (:formulae raw))
           (parse (:casks raw)))))

(defn services-map
  "Return {name service-info} from brew services list."
  []
  (let [services (-> (d/with-spinner "Listing Homebrew services"
                       (process/shell {:out :string :err :string} "brew" "services" "list" "--json"))
                     :out
                     (json/parse-string true))]
    (into {} (map (fn [s] [(:name s) s])) services)))

(defn trusted-map
  "Return {:formulae #{...} :casks #{...} :taps #{...}} from brew trust --json v1."
  []
  (let [raw (-> (d/with-spinner "Reading Homebrew trust store"
                  (process/shell {:out :string :err :string} "brew" "trust" "--json" "v1"))
                :out
                (json/parse-string true))]
    {:formulae (set (:formulae raw))
     :casks (set (:casks raw))
     :taps (set (:taps raw))}))

;; Module-level caching — each delay runs at most once per process.
(def ^:dynamic *formulae-cache* (delay (installed-set :formula)))
(def ^:dynamic *casks-cache* (delay (installed-set :cask)))
(def ^:dynamic *outdated-cache* (delay (outdated-map)))
(def ^:dynamic *services-cache* (delay (services-map)))
(def ^:dynamic *trusted-cache* (delay (trusted-map)))

(defn- short-name
  "Extract short name from tap-qualified brew name.
   e.g. 'babashka/brew/bbin' -> 'bbin', 'neovim' -> 'neovim'"
  [full-name]
  (last (str/split full-name #"/")))

(defn tap-of
  "Return the tap a qualified brew name comes from, nil for official names.
   e.g. 'babashka/brew/bbin' -> 'babashka/brew', 'neovim' -> nil"
  [full-name]
  (let [parts (str/split full-name #"/")]
    (when (= 3 (count parts))
      (str/join "/" (take 2 parts)))))

(defn- trusted?
  "Is this tap-qualified name covered by a trust grant — its own, or its tap's?"
  [full-name]
  (let [{:keys [formulae casks taps]} @*trusted-cache*]
    (boolean (or (contains? (or formulae #{}) full-name)
                 (contains? (or casks #{}) full-name)
                 (contains? (or taps #{}) (tap-of full-name))))))

(defn- trust-check
  "Trust outcome for a tap-qualified package, nil when trust needs no attention.
   Precedes the installed/outdated logic: brew ignores items from untrusted
   taps, so its answers about them are unreliable."
  [pkg-name declared? installed?]
  (let [granted? (trusted? pkg-name)]
    (cond
      (and declared? (not granted?))
      (assoc (o/drift :wrong) :message "untrusted")

      (and granted? (not declared?))
      (assoc (o/drift :wrong) :message "trusted but :trust not declared — revoking")

      (and (not granted?) (not declared?))
      (if installed?
        (assoc o/satisfied :message "untrusted tap — declare :trust to re-enable updates")
        (o/conflict "untrusted tap — declare :trust to allow install")))))

(defmethod a/check :pkg/brew [_ key opts]
  (let [pkg-name (name key)
        sn (short-name pkg-name)
        formulae @*formulae-cache*
        casks @*casks-cache*
        outdated @*outdated-cache*
        installed? (or (contains? formulae sn)
                       (contains? casks sn))
        out-info (or (get outdated sn)
                     (get outdated pkg-name))]
    (or (when (tap-of pkg-name)
          (trust-check pkg-name (boolean (:trust opts)) installed?))
        (cond
          out-info (assoc (o/drift :outdated) :message (str (:installed out-info) " → " (:current out-info)))
          installed? o/satisfied
          :else (o/drift :missing)))))

(defmethod a/check :brew/service [_ key opts]
  (let [svc-name (name key)
        by-name @*services-cache*
        svc (get by-name svc-name)]
    (cond
      (nil? svc) (o/drift :missing)
      (= "started" (:status svc)) o/satisfied
      ;; sudo services show status "none" in non-sudo brew services list
      (and (:sudo opts) (= "root" (:user svc))) o/satisfied
      :else (o/drift :missing))))

(defmethod a/check :pkg/brew-uninstall [_ key opts]
  (o/drift :orphan))

(defn leaves-set
  "Return #{name ...} of explicitly installed formulae (not deps).
   Uses `brew leaves --installed-on-request` to exclude transitive dependencies."
  []
  (d/with-spinner "Listing explicitly installed Homebrew formulae"
    (->> (process/shell {:out :string :err :string} "brew" "leaves" "--installed-on-request")
         :out
         str/split-lines
         (remove str/blank?)
         set)))

(defn installed-set-full
  "Return #{name ...} of installed formulae with full tap-qualified names."
  [kind]
  (let [flag (if (= kind :cask) "--cask" "--formula")]
    (d/with-spinner (str "Listing Homebrew " (if (= kind :cask) "casks" "formulae"))
      (->> (process/shell {:out :string :err :string} "brew" "list" flag "--full-name" "-1")
           :out
           str/split-lines
           (remove str/blank?)
           set))))

(defn parse-deps-graph
  "Parse output of `brew deps --installed` into {pkg #{dep1 dep2 ...}}.
   Each line is `name: dep1 dep2 ...`."
  [output]
  (if (str/blank? output)
    {}
    (->> (str/split-lines output)
         (map (fn [line]
                (let [[pkg deps-str] (str/split line #":\s*" 2)]
                  [pkg (if (str/blank? deps-str)
                         #{}
                         (set (str/split deps-str #"\s+")))])))
         (into {}))))

(defn deps-graph
  "Return {pkg #{dep1 dep2 ...}} from `brew deps --installed`."
  []
  (d/with-spinner "Resolving Homebrew dependency graph"
    (->> (process/shell {:out :string :err :string} "brew" "deps" "--installed")
         :out
         parse-deps-graph)))

(defn transitive-deps-of
  "Given a set of declared package names and a deps graph,
   compute the full transitive closure of their dependencies (excluding the declared set itself)."
  [declared graph]
  (loop [seen #{}
         queue (vec declared)]
    (if (empty? queue)
      (set/difference seen declared)
      (let [pkg (peek queue)
            deps (get graph pkg #{})
            new-deps (remove seen deps)]
        (recur (into seen deps)
               (into (pop queue) new-deps))))))

(defn- declared-names
  "Extract the set of names from declared :pkg/brew items.
   Returns both the raw name and its short form for tap-qualified names."
  [brew-items]
  (reduce (fn [s [k _]]
            (let [n (name k)]
              (-> s (conj n) (conj (short-name n)))))
          #{}
          brew-items))

(defn- declared?
  "Check if an installed package name matches any declared name."
  [declared-set installed-name]
  (or (contains? declared-set installed-name)
      (contains? declared-set (short-name installed-name))))

(defn orphans
  "Find brew formulae/casks that are leaves (explicitly installed) but not declared.
   installed-state is {:formulae #{...} :casks #{...}}.
   declared-items is the :pkg/brew map from the plan."
  [{:keys [formulae casks]} declared-items]
  (let [declared (declared-names declared-items)
        formula-orphans (->> formulae
                             (remove (fn [f] (declared? declared f)))
                             (map (fn [f] [f {}]))
                             (into {}))
        cask-orphans (->> casks
                          (remove (fn [c] (declared? declared c)))
                          (map (fn [c] [c {}]))
                          (into {}))]
    (merge formula-orphans cask-orphans)))

(defn installed-taps
  "Return #{tap ...} of installed third-party taps."
  []
  (d/with-spinner "Listing Homebrew taps"
    (->> (process/shell {:out :string :err :string} "brew" "tap")
         :out
         str/split-lines
         (remove str/blank?)
         set)))

(defn orphan-taps
  "Find installed taps that no declared package comes from.
   declared-items is the :pkg/brew map from the plan."
  [installed declared-items]
  (let [in-use (into #{} (keep (fn [[k _]] (tap-of (name k)))) declared-items)]
    (->> installed
         (remove in-use)
         (map (fn [tap] [tap {}]))
         (into {}))))

(defmethod a/orphans :pkg/brew [_ declared]
  (when (u/command-exists? "brew")
    (let [pkgs (orphans {:formulae (leaves-set) :casks (installed-set-full :cask)} declared)
          taps (orphan-taps (installed-taps) declared)]
      (merge (when (seq pkgs) {:pkg/brew-uninstall pkgs})
             (when (seq taps) {:brew/untap taps})))))

(defn- install-commands
  "The command sequence that makes one declared package true: converge the
   trust grant on the :trust declaration (per item, never the whole tap),
   then install if the package itself is absent or being upgraded."
  [pkg-name {:keys [head cask trust]}]
  (let [tap (tap-of pkg-name)
        granted? (and tap (trusted? pkg-name))
        grant? (and tap trust (not granted?))
        revoke? (and granted? (not trust))
        installed? (or (contains? @*formulae-cache* (short-name pkg-name))
                       (contains? @*casks-cache* (short-name pkg-name)))
        flag (if cask "--cask" "--formula")]
    (cond-> []
      grant? (conj ["brew" "trust" flag pkg-name])
      revoke? (conj ["brew" "untrust" flag pkg-name])
      (and (not revoke?)
           (or (not grant?) (not installed?)))
      (conj (cond-> ["brew" "install"]
              cask (conj "--cask")
              true (conj pkg-name)
              head (conj "--HEAD"))))))

(defn- run-commands!
  "Run cmds in order, stopping at the first failure. Returns {:exit :err}."
  [opts cmds]
  (reduce (fn [_ cmd]
            (let [{:keys [exit] :as result} (a/exec! opts cmd)]
              (if (zero? exit) result (reduced result))))
          {:exit 0 :err nil}
          cmds))

(defmethod a/install! :pkg/brew [type opts items]
  (d/section "Installing brew packages"
    (map (fn [[pkg item-opts]]
           (let [{:keys [exit err]} (run-commands! opts (install-commands (name pkg) item-opts))]
             {:action [type pkg]
              :label (name pkg)
              :status (if (zero? exit) :ok :error)
              :message err}))
         items)))

;; -- Uninstall orphans

(defmethod a/requires :pkg/brew-uninstall [_] [:complete :pkg/brew])

(defmethod a/install! :pkg/brew-uninstall [type opts items]
  (let [results (d/section "Uninstalling brew orphans"
                  (map (fn [[pkg _]]
                         (let [pkg-name (if (keyword? pkg) (name pkg) (str pkg))
                               cmds (cond-> []
                                      ;; no grant outlives the package it was made for
                                      (and (tap-of pkg-name) (trusted? pkg-name))
                                      (conj ["brew" "untrust" "--formula" pkg-name])
                                      true (conj ["brew" "uninstall" pkg-name]))
                               {:keys [exit err]} (run-commands! opts cmds)]
                           {:action [type pkg]
                            :label pkg-name
                            :status (if (zero? exit) :ok :error)
                            :message err}))
                       items))]
    (a/exec! opts ["brew" "autoremove"])
    results))

;; -- Untap orphan sources

(defmethod a/requires :brew/untap [_] [:complete :pkg/brew])

(defmethod a/check :brew/untap [_ key opts]
  (o/drift :orphan))

(defmethod a/install! :brew/untap [type opts items]
  (a/simple-install type opts "Removing orphaned brew taps"
    (fn [tap _] ["brew" "untap" (name tap)])
    items))

(defmethod a/install! :brew/service [type opts items]
  (a/simple-install type opts "Starting brew services"
    (fn [svc {:keys [restart sudo]}]
      (let [cmd (if restart
                  ["brew" "services" "restart" (name svc)]
                  ["brew" "services" "start" (name svc)])]
        (if sudo
          (into ["sudo"] cmd)
          cmd)))
    items))
