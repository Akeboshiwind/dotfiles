(ns actions.uv
  (:require [actions :as a]
            [clojure.string :as str]
            [display :as d]
            [facts :as f]
            [outcome :as o]
            [utils.sh :as sh]))

(defmethod a/requires :uv/tool [_] :uv/tool)

(defn installed-set
  "Return #{name ...} of installed uv tools."
  []
  (let [result (d/with-spinner "Listing uv tools"
                 (sh/query! `installed-set {:continue true} ["uv" "tool" "list"]))]
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

(defmethod a/run-query :uv [[_ what]]
  (case what
    :installed (installed-set)))

(defmethod a/orphan-queries :uv/tool [_ _]
  #{[:command "uv"] [:uv :installed]})

(defmethod a/orphans :uv/tool [_ declared facts]
  (when (f/value facts [:command "uv"])
    (let [result (orphans (f/value facts [:uv :installed]) declared)]
      (when (seq result)
        {:uv/tool-uninstall result}))))

(defmethod a/queries :uv/tool [_ _] #{[:uv :installed]})

(defmethod a/check :uv/tool [_ key _opts facts]
  (let [installed (f/value facts [:uv :installed])]
    (if (contains? installed (name key))
      o/satisfied
      (o/drift :missing))))

(defmethod a/check :uv/tool-uninstall [_ _key _opts _facts]
  (o/drift :orphan))

(defmethod a/install! :uv/tool [type opts items _facts]
  (a/simple-install type opts "Installing uv tools"
    (fn [pkg item-opts]
      (let [pkg-name (name pkg)
            from (or (:from item-opts) pkg-name)]
        (cond-> ["uv" "tool" "install" from]
          (:with item-opts) (into ["--with" (:with item-opts)]))))
    items))

;; -- Uninstall orphans

(defmethod a/requires :uv/tool-uninstall [_] [:complete :uv/tool])

(defmethod a/install! :uv/tool-uninstall [type opts items _facts]
  (a/simple-install type opts "Uninstalling uv tool orphans"
    (fn [pkg _] ["uv" "tool" "uninstall" (name pkg)])
    items))
