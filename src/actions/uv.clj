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

(defmethod a/run-query :uv [[_ what]]
  (case what
    :installed (installed-set)))

(defmethod a/extras-queries :uv/tool [_] #{[:command "uv"] [:uv :installed]})

(defmethod a/extras :uv/tool [_ declared facts]
  (if (f/value facts [:command "uv"])
    (->> (f/value facts [:uv :installed]) (remove declared) sort (mapv (fn [n] {:name n})))
    []))

(defmethod a/queries :uv/tool [_ _] #{[:uv :installed]})

(defmethod a/check :uv/tool [_ key _opts facts]
  (let [installed (f/value facts [:uv :installed])]
    (if (contains? installed (name key))
      o/satisfied
      (o/drift :missing))))

(defmethod a/install! :uv/tool [type opts items _facts]
  (a/simple-install type opts "Installing uv tools"
    (fn [pkg item-opts]
      (let [pkg-name (name pkg)
            from (or (:from item-opts) pkg-name)]
        (cond-> ["uv" "tool" "install" from]
          (:with item-opts) (into ["--with" (:with item-opts)]))))
    items))

(defmethod a/remove-extras! :uv/tool [type opts extras _facts]
  (a/simple-install type opts "Uninstalling uv tools"
    (fn [pkg _] ["uv" "tool" "uninstall" pkg])
    (into {} (map (fn [{n :name}] [n {}])) extras)))
