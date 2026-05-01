(ns actions.uv
  (:require [actions :as a]
            [babashka.process :as process]
            [clojure.string :as str]
            [outcome :as o]
            [utils :as u]))

(defmethod a/requires :uv/tool [_] :uv/tool)

(defn installed-set
  "Return #{name ...} of installed uv tools."
  []
  (let [result (process/shell {:out :string :err :string :continue true}
                              "uv" "tool" "list")]
    (if (zero? (:exit result))
      (->> (:out result)
           str/split-lines
           (keep (fn [line]
                   (when-not (or (str/blank? line)
                                 (str/starts-with? line " ")
                                 (str/starts-with? line "- "))
                     (first (str/split line #"\s")))))
           set)
      #{})))

(defn orphans
  "Find uv tools installed but not declared."
  [installed-names declared-items]
  (let [declared (into #{} (map (comp name key)) declared-items)]
    (->> installed-names
         (remove declared)
         (map (fn [n] [(keyword n) {}]))
         (into {}))))

(defmethod a/orphans :uv/tool [_ declared]
  (when (u/command-exists? "uv")
    (let [result (orphans (installed-set) declared)]
      (when (seq result)
        {:uv/tool-uninstall result}))))

(def ^:dynamic *installed-cache* (delay (installed-set)))

(defmethod a/check :uv/tool [_ key _opts]
  (let [installed @*installed-cache*]
    (if (contains? installed (name key))
      o/satisfied
      (o/drift :missing))))

(defmethod a/check :uv/tool-uninstall [_ _key _opts]
  (o/drift :orphan))

(defmethod a/install! :uv/tool [type opts items]
  (a/simple-install type opts "Installing uv tools"
    (fn [pkg item-opts]
      (let [pkg-name (name pkg)
            from (or (:from item-opts) pkg-name)]
        (cond-> ["uv" "tool" "install" from]
          (:with item-opts) (into ["--with" (:with item-opts)]))))
    items))

;; -- Uninstall orphans

(defmethod a/requires :uv/tool-uninstall [_] [:complete :uv/tool])

(defmethod a/install! :uv/tool-uninstall [type opts items]
  (a/simple-install type opts "Uninstalling uv tool orphans"
    (fn [pkg _] ["uv" "tool" "uninstall" (name pkg)])
    items))
