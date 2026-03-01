(ns actions.brew
  (:require [actions :as a]
            [babashka.process :as process]
            [cheshire.core :as json]
            [clojure.set :as set]
            [clojure.string :as str]
            [outcome :as o]))

(defmethod a/requires :pkg/brew [_] :pkg/brew)
(defmethod a/requires :brew/service [_] :brew/service)

(defn installed-set
  "Return #{name ...} of installed formulae or casks."
  [kind]
  (let [flag (if (= kind :cask) "--cask" "--formula")]
    (->> (process/shell {:out :string :err :string} "brew" "list" flag "-1")
         :out
         str/split-lines
         (remove str/blank?)
         set)))

(defn outdated-map
  "Return {name {:installed v1 :current v2}} from brew outdated."
  []
  (let [raw (-> (process/shell {:out :string :err :string} "brew" "outdated" "--json=v2")
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
  (let [services (-> (process/shell {:out :string :err :string} "brew" "services" "list" "--json")
                     :out
                     (json/parse-string true))]
    (into {} (map (fn [s] [(:name s) s])) services)))

;; Module-level caching — each delay runs at most once per process.
(def ^:dynamic *formulae-cache* (delay (installed-set :formula)))
(def ^:dynamic *casks-cache* (delay (installed-set :cask)))
(def ^:dynamic *outdated-cache* (delay (outdated-map)))
(def ^:dynamic *services-cache* (delay (services-map)))

(defn- short-name
  "Extract short name from tap-qualified brew name.
   e.g. 'babashka/brew/bbin' -> 'bbin', 'neovim' -> 'neovim'"
  [full-name]
  (last (str/split full-name #"/")))

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
    (cond
      out-info (o/drift :outdated)
      installed? o/satisfied
      :else (o/drift :missing))))

(defmethod a/check :brew/service [_ key opts]
  (let [svc-name (name key)
        by-name @*services-cache*
        svc (get by-name svc-name)]
    (cond
      (nil? svc) (o/drift :missing)
      (= "started" (:status svc)) o/satisfied
      :else (o/drift :missing))))

(defmethod a/check :pkg/brew-uninstall [_ key opts]
  (o/drift :orphan))

(defn leaves-set
  "Return #{name ...} of explicitly installed formulae (not deps).
   Uses `brew leaves --installed-on-request` to exclude transitive dependencies."
  []
  (->> (process/shell {:out :string :err :string} "brew" "leaves" "--installed-on-request")
       :out
       str/split-lines
       (remove str/blank?)
       set))

(defn installed-set-full
  "Return #{name ...} of installed formulae with full tap-qualified names."
  [kind]
  (let [flag (if (= kind :cask) "--cask" "--formula")]
    (->> (process/shell {:out :string :err :string} "brew" "list" flag "--full-name" "-1")
         :out
         str/split-lines
         (remove str/blank?)
         set)))

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
  (->> (process/shell {:out :string :err :string} "brew" "deps" "--installed")
       :out
       parse-deps-graph))

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

(defmethod a/orphans :pkg/brew [_ declared]
  (let [result (orphans {:formulae (leaves-set) :casks (installed-set-full :cask)} declared)]
    (when (seq result)
      {:pkg/brew-uninstall result})))

(defmethod a/status :pkg/brew [type items _ctx]
  (let [formulae @*formulae-cache*
        casks @*casks-cache*
        outdated @*outdated-cache*]
    (mapv (fn [[k opts]]
            (let [pkg-name (name k)
                  ;; Strip tap prefix (e.g. "babashka/brew/bbin" → "bbin")
                  short-name (last (str/split pkg-name #"/"))
                  installed? (or (contains? formulae short-name)
                                 (contains? casks short-name))
                  out-info (or (get outdated short-name)
                               (get outdated pkg-name))]
              {:label pkg-name
               :action [type k]
               :state (cond
                        out-info :outdated
                        installed? :installed
                        :else :missing)
               :detail (when out-info
                         (str "(" (:installed out-info) " → " (:current out-info) ")"))}))
          items)))

(defmethod a/status :brew/service [type items _ctx]
  (let [by-name @*services-cache*]
    (mapv (fn [[k _opts]]
            (let [svc-name (name k)
                  svc (get by-name svc-name)]
              {:label svc-name
               :action [type k]
               :state (cond
                        (nil? svc) :missing
                        (= "started" (:status svc)) :installed
                        :else :missing)
               :detail (when svc (str "(" (:status svc) ")"))}))
          items)))

(defmethod a/install! :pkg/brew [type opts items]
  (a/simple-install type opts "Installing brew packages"
    (fn [pkg {:keys [head cask]}]
      (cond-> ["brew" "install"]
        cask (conj "--cask")
        true (conj (name pkg))
        head (conj "--HEAD")))
    items))

;; -- Uninstall orphans

(defmethod a/requires :pkg/brew-uninstall [_] nil)

(defmethod a/status :pkg/brew-uninstall [type items _ctx]
  (mapv (fn [[k _]]
          {:label (if (keyword? k) (name k) (str k))
           :state :orphan
           :action [type k]})
        items))

(defmethod a/install! :pkg/brew-uninstall [type opts items]
  (let [results (a/simple-install type opts "Uninstalling brew orphans"
                  (fn [pkg _] ["brew" "uninstall" (if (keyword? pkg) (name pkg) (str pkg))])
                  items)]
    (a/exec! opts ["brew" "autoremove"])
    results))

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
