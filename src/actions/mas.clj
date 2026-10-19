(ns actions.mas
  (:require [actions :as a]
            [clojure.string :as str]
            [display :as d]
            [facts :as f]
            [outcome :as o]
            [utils.sh :as sh]))

(defmethod a/requires :pkg/mas [_] :pkg/mas)

(defn installed-map
  "Return {id app-name} of installed Mac App Store apps."
  []
  (let [lines (-> (d/with-spinner "Listing Mac App Store apps"
                    (sh/query! `installed-map ["mas" "list"]))
                  :out
                  str/split-lines)]
    (into {} (keep (fn [line]
                     (when-let [[_ id app-name] (re-matches #"\s*(\d+)\s+(.+?)(?:\s+\(.*\))?\s*$" line)]
                       [(parse-long id) (str/trim app-name)])))
          lines)))

(defmethod a/run-query :mas [[_ what]]
  (case what
    :installed (installed-map)))

(defmethod a/manifest :pkg/mas [_] {:syn/exclusive {:pkg/mas {}}})

(defmethod a/extras-queries :pkg/mas [_] #{[:command "mas"] [:mas :installed]})

(defmethod a/extras :pkg/mas [_ declared facts]
  (if (f/value facts [:command "mas"])
    (->> (f/value facts [:mas :installed])
         (remove (fn [[id _]] (contains? declared (str id))))
         (sort-by key)
         (mapv (fn [[id app-name]] {:name (str id) :label app-name})))
    []))

(defmethod a/queries :pkg/mas [_ _] #{[:mas :installed]})

(defmethod a/check :pkg/mas [_ app-id _app-name facts]
  (cond
    (not (int? app-id))
    (o/error (str "mas apps are declared {app-id name}, got key " (pr-str app-id)))

    (contains? (f/value facts [:mas :installed]) app-id)
    o/satisfied

    :else
    (o/drift :missing)))

(defmethod a/install! :pkg/mas [type opts items _facts]
  (a/simple-install type opts "Installing Mac App Store apps"
    (fn [_app-id app-name] app-name)
    (fn [app-id _app-name]
      ["mas" "install" (str app-id)])
    items))

(defmethod a/remove-extras! :pkg/mas [type opts extras _facts]
  (a/simple-install type opts "Uninstalling Mac App Store apps"
    (fn [id {:keys [label]}] (or label id))
    (fn [id _] ["mas" "uninstall" id])
    (into {} (map (fn [{n :name :as extra}] [n extra])) extras)))
