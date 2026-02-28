(ns actions.brew
  (:require [actions :as a]
            [babashka.process :as process]
            [cheshire.core :as json]
            [clojure.string :as str]))

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

(defmethod a/status :pkg/brew [type items ctx]
  (let [formulae @(:brew/formulae ctx)
        casks @(:brew/casks ctx)
        outdated @(:brew/outdated ctx)]
    (mapv (fn [[k opts]]
            (let [pkg-name (name k)
                  installed? (or (contains? formulae pkg-name)
                                 (contains? casks pkg-name))
                  out-info (get outdated pkg-name)]
              {:label pkg-name
               :action [type k]
               :state (cond
                        out-info :outdated
                        installed? :installed
                        :else :missing)
               :detail (when out-info
                         (str "(" (:installed out-info) " → " (:current out-info) ")"))}))
          items)))

(defmethod a/status :brew/service [type items ctx]
  (let [by-name @(:brew/services ctx)]
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
