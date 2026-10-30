(ns actions.brew
  (:require [actions :as a]
            [cheshire.core :as json]
            [clojure.set :as set]
            [clojure.string :as str]
            [display :as d]
            [facts :as f]
            [outcome :as o]
            [utils.sh :as sh]))

(defmethod a/requires :pkg/brew [_] :pkg/brew)
(defmethod a/requires :brew/service [_] :brew/service)

(defn installed-set
  "Return #{name ...} of installed formulae or casks."
  [kind]
  (let [flag (if (= kind :cask) "--cask" "--formula")]
    (d/with-spinner (str "Listing Homebrew " (if (= kind :cask) "casks" "formulae"))
      (->> (sh/query! `installed-set ["brew" "list" flag "-1"])
           :out
           str/split-lines
           (remove str/blank?)
           set))))

(defn outdated-map
  "Return {name {:installed v1 :current v2}} from brew outdated."
  []
  (let [raw (-> (d/with-spinner "Checking for outdated Homebrew packages"
                  (sh/query! `outdated-map ["brew" "outdated" "--json=v2"]))
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
                       (sh/query! `services-map ["brew" "services" "list" "--json"]))
                     :out
                     (json/parse-string true))]
    (into {} (map (fn [s] [(:name s) s])) services)))

(defn trusted-map
  "Return {:formulae #{...} :casks #{...} :taps #{...}} from brew trust --json v1."
  []
  (let [raw (-> (d/with-spinner "Reading Homebrew trust store"
                  (sh/query! `trusted-map ["brew" "trust" "--json" "v1"]))
                :out
                (json/parse-string true))]
    {:formulae (set (:formulae raw))
     :casks (set (:casks raw))
     :taps (set (:taps raw))}))

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

(defn- trust-queries [items]
  (when (some (fn [[k _]] (tap-of (name k))) items)
    #{[:brew :trusted]}))

(defn- trusted?
  "Is this tap-qualified name covered by a trust grant in trust (a trusted-map
   result) — its own, or its tap's?"
  [trust full-name]
  (let [{:keys [formulae casks taps]} trust]
    (boolean (or (contains? (or formulae #{}) full-name)
                 (contains? (or casks #{}) full-name)
                 (contains? (or taps #{}) (tap-of full-name))))))

(defn- trust-check
  "Trust outcome for a tap-qualified package, nil when trust needs no attention.
   Precedes the installed/outdated logic: brew ignores items from untrusted
   taps, so its answers about them are unreliable."
  [trust pkg-name declared? installed?]
  (let [granted? (trusted? trust pkg-name)]
    (cond
      (and declared? (not granted?))
      (assoc (o/drift :wrong) :message "untrusted")

      (and granted? (not declared?))
      (assoc (o/drift :wrong) :message "trusted but :trust not declared — revoking")

      (and (not granted?) (not declared?))
      (if installed?
        (assoc o/satisfied :message "untrusted tap — declare :trust to re-enable updates")
        (o/conflict "untrusted tap — declare :trust to allow install")))))

(defmethod a/queries :pkg/brew [_ declared]
  (into #{[:brew :formulae] [:brew :casks] [:brew :outdated]} (trust-queries declared)))

(defmethod a/check :pkg/brew [_ key opts facts]
  (let [pkg-name (name key)
        sn (short-name pkg-name)
        formulae (f/value facts [:brew :formulae])
        casks (f/value facts [:brew :casks])
        outdated (f/value facts [:brew :outdated])
        installed? (or (contains? formulae sn)
                       (contains? casks sn))
        out-info (or (get outdated sn)
                     (get outdated pkg-name))]
    (or (when (tap-of pkg-name)
          (trust-check (f/value facts [:brew :trusted]) pkg-name (boolean (:trust opts)) installed?))
        (cond
          out-info (o/version-drift (:installed out-info) (:current out-info))
          installed? o/satisfied
          :else (o/drift :missing)))))

(defmethod a/queries :brew/service [_ _] #{[:brew :services]})

(defmethod a/check :brew/service [_ key opts facts]
  (let [svc-name (name key)
        by-name (f/value facts [:brew :services])
        svc (get by-name svc-name)]
    (cond
      (nil? svc) (o/drift :missing)
      (= "started" (:status svc)) o/satisfied
      ;; sudo services show status "none" in non-sudo brew services list
      (and (:sudo opts) (= "root" (:user svc))) o/satisfied
      :else (o/drift :missing))))

(defn leaves-set
  "Return #{name ...} of explicitly installed formulae (not deps).
   Uses `brew leaves --installed-on-request` to exclude transitive dependencies."
  []
  (d/with-spinner "Listing explicitly installed Homebrew formulae"
    (->> (sh/query! `leaves-set ["brew" "leaves" "--installed-on-request"])
         :out
         str/split-lines
         (remove str/blank?)
         set)))

(defn installed-set-full
  "Return #{name ...} of installed formulae with full tap-qualified names."
  [kind]
  (let [flag (if (= kind :cask) "--cask" "--formula")]
    (d/with-spinner (str "Listing Homebrew " (if (= kind :cask) "casks" "formulae"))
      (->> (sh/query! `installed-set-full ["brew" "list" flag "--full-name" "-1"])
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
    (->> (sh/query! `deps-graph ["brew" "deps" "--installed"])
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

(defn extra-packages
  "The explicitly installed formulae and casks no declared name covers. A
   tap-qualified name and its short form cover each other."
  [{:keys [formulae casks]} declared]
  (let [covered (into declared (map short-name) declared)]
    (into (sorted-set)
          (remove #(or (contains? covered %) (contains? covered (short-name %))))
          (concat formulae casks))))

(defn installed-taps
  "Return #{tap ...} of installed third-party taps."
  []
  (d/with-spinner "Listing Homebrew taps"
    (->> (sh/query! `installed-taps ["brew" "tap"])
         :out
         str/split-lines
         (remove str/blank?)
         set)))

(defn extra-taps
  "The installed taps no declared name comes from."
  [installed declared]
  (into (sorted-set) (remove (set (keep tap-of declared))) installed))

(defmethod a/run-query :brew [[_ what]]
  (case what
    :formulae (installed-set :formula)
    :casks (installed-set :cask)
    :outdated (outdated-map)
    :services (services-map)
    :trusted (trusted-map)
    :leaves (leaves-set)
    :casks-full (installed-set-full :cask)
    :taps (installed-taps)))

(defmethod a/manifest :pkg/brew [_] {:syn/exclusive {:pkg/brew {}}})

(defmethod a/extras-queries :pkg/brew [_]
  #{[:command "brew"] [:brew :leaves] [:brew :casks-full] [:brew :taps]})

(defmethod a/extras :pkg/brew [_ declared facts]
  (if (f/value facts [:command "brew"])
    (into (let [formulae (extra-packages {:formulae (f/value facts [:brew :leaves])} declared)
                casks (remove formulae (extra-packages {:casks (f/value facts [:brew :casks-full])} declared))]
            (->> (concat (map (fn [n] {:name n}) formulae)
                         (map (fn [n] {:name n :cask true}) casks))
                 (sort-by :name)
                 vec))
          (map (fn [t] {:name t :tap true}))
          (extra-taps (f/value facts [:brew :taps]) declared))
    []))

(defmethod a/removal-queries :pkg/brew [_] #{[:brew :trusted]})

(defmethod a/install-queries :pkg/brew [_ items]
  (into #{[:brew :formulae] [:brew :casks]} (trust-queries items)))

(defn- install-commands
  "The command sequence that makes one declared package true: converge the
   trust grant on the :trust declaration (per item, never the whole tap),
   then install if the package itself is absent or being upgraded."
  [facts pkg-name {:keys [head cask trust]}]
  (let [tap (tap-of pkg-name)
        granted? (and tap (trusted? (f/value facts [:brew :trusted]) pkg-name))
        grant? (and tap trust (not granted?))
        revoke? (and granted? (not trust))
        installed? (or (contains? (f/value facts [:brew :formulae]) (short-name pkg-name))
                       (contains? (f/value facts [:brew :casks]) (short-name pkg-name)))
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

(defmethod a/install! :pkg/brew [type opts items facts]
  (d/section "Installing brew packages"
    (map (fn [[pkg item-opts]]
           (let [{:keys [exit err]} (run-commands! opts (install-commands facts (name pkg) item-opts))]
             {:action [type pkg]
              :label (name pkg)
              :status (if (zero? exit) :ok :error)
              :message err}))
         items)))

(defn- remove-package! [type opts facts pkg-name]
  (let [cmds (cond-> []
               ;; no grant outlives the package it was made for
               (and (tap-of pkg-name) (trusted? (f/value facts [:brew :trusted]) pkg-name))
               (conj ["brew" "untrust" "--formula" pkg-name])
               true (conj ["brew" "uninstall" pkg-name]))
        {:keys [exit err]} (run-commands! opts cmds)]
    {:action [type pkg-name]
     :label pkg-name
     :status (if (zero? exit) :ok :error)
     :message err}))

(defmethod a/remove-extras! :pkg/brew [type opts extras facts]
  (let [{taps true pkgs false} (group-by (comp boolean :tap) extras)
        removed (d/section "Uninstalling brew packages"
                  (map (fn [{n :name}] (remove-package! type opts facts n)) pkgs))]
    (when (seq pkgs)
      (a/exec! opts ["brew" "autoremove"]))
    (into removed
          (when (seq taps)
            (a/simple-install type opts "Removing brew taps"
              (fn [tap _] ["brew" "untap" tap])
              (into {} (map (fn [{t :name}] [t {}])) taps))))))

(defmethod a/install! :brew/service [type opts items _facts]
  (a/simple-install type opts "Starting brew services"
    (fn [svc {:keys [restart sudo]}]
      (let [cmd (if restart
                  ["brew" "services" "restart" (name svc)]
                  ["brew" "services" "start" (name svc)])]
        (if sudo
          (into ["sudo"] cmd)
          cmd)))
    items))
