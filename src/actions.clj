(ns actions
  "Action multimethod registry for dotfile management.
   Each action type (e.g. :pkg/brew) implements install! in its own namespace."
  (:require [clojure.java.io :as io]
            [clojure.string :as str]
            [babashka.process :as process]
            [display :as d]))

;; =============================================================================
;; Execution
;; =============================================================================

(def ^:private default-prefix "    ")

(defn- prefix-print
  ([stream] (prefix-print default-prefix stream))
  ([prefix stream]
   (with-open [rdr (io/reader stream)]
     (doseq [line (line-seq rdr)]
       (println prefix (d/gray line))))))

(defn exec!
  "Execute a command.
   Options: :dry-run to preview, :prefix for output line prefix (default \"    \"),
            :env map of extra environment variables to pass to the process.
   Returns {:exit int :err string-or-nil}"
  [{:keys [dry-run prefix env] :or {prefix default-prefix}} args]
  (if dry-run
    (do
      (println prefix (d/gray (str/join " " args)))
      {:exit 0 :err nil})
    (let [proc (process/process args (cond-> {:err :string :in :inherit}
                                       env (assoc :extra-env env)))
          out-future (future (prefix-print prefix (:out proc)))
          result @proc]
      @out-future
      {:exit (:exit result)
       :err (let [e (:err result)]
              (when (and e (seq (str/trim e)))
                (-> e
                    str/trim
                    (str/replace #"\s*\n\s*" " "))))})))

;; =============================================================================
;; Helpers
;; =============================================================================

(defn simple-install
  "Helper for actions that follow the common pattern: run a command for each item.
   - action-type: the action type keyword (e.g. :pkg/brew), used for :action in results
   - opts: execution options (passed to exec!, includes :dry-run)
   - title: section title
   - label-fn: (fn [key item-opts] -> string)
   - cmd-fn: (fn [key item-opts] -> command vector)
   - items: map of {key item-opts}"
  ([action-type opts title cmd-fn items]
   (simple-install action-type opts title (fn [k _] (name k)) cmd-fn items))
  ([action-type opts title label-fn cmd-fn items]
   (d/section title
     (map (fn [[k item-opts]]
            (let [{:keys [exit err]} (exec! opts (cmd-fn k item-opts))]
              {:action [action-type k]
               :label (label-fn k item-opts)
               :status (if (zero? exit) :ok :error)
               :message err}))
          items))))

;; =============================================================================
;; Multimethods
;; =============================================================================

(defmulti requires
  "Return the capability keyword this action type requires, or nil if standalone.
   Non-nil values must be provided by another action via :dep/provides.
   Default: requires its own type (must be explicitly provided)."
  identity)

(defmethod requires :default [type] type)

(defmulti validate
  "Validate items of a given action type.
   Returns seq of error maps {:action :key :error}, or nil if valid."
  (fn [type _items] type))

(defmethod validate :default [_ _] nil)

(defmulti status
  "Check installed state of items. No side effects.
   ctx is a map of delays for shared/expensive data (e.g. brew list results).
   Returns seq of {:label str :state kw :detail str? :action [type key]}"
  (fn [type _items _ctx] type))

(defmethod status :default [type items _ctx]
  (mapv (fn [[k _]] {:label (name k) :state :unknown :action [type k]}) items))

(defmulti install!
  "Install items of a given action type.
   Dispatches on action type keyword (e.g. :pkg/brew).
   Receives [type opts items] where:
   - type: action keyword
   - opts: execution options (includes :dry-run)
   - items: map of {name item-opts}"
  (fn [type _opts _items] type))

(defmethod install! :default [type _opts _items]
  (println "Warning: no install! implementation for" type))

;; =============================================================================
;; Capability introspection
;; =============================================================================

(defn supports?
  "Check if action type has an implementation (not just :default)"
  [type]
  (and (contains? (methods install!) type)
       (not= (get (methods install!) type)
             (get (methods install!) :default))))

(defn supported-types
  "Return all action types with implementations"
  []
  (->> (methods install!)
       keys
       (remove #{:default})
       set))

;; =============================================================================
;; Result validation
;; =============================================================================

(defn validate-result!
  "Validate a single result map from install!. Throws with a specific message on failure."
  [action-type result]
  (when-not (map? result)
    (throw (ex-info (str "install! for " action-type " returned non-map result: " (pr-str result))
                    {:action-type action-type :result result})))
  (when-not (string? (:label result))
    (throw (ex-info (str "install! for " action-type " result missing string :label, got: " (pr-str (:label result)))
                    {:action-type action-type :result result})))
  (when-not (#{:ok :skip :error} (:status result))
    (throw (ex-info (str "install! for " action-type " result has invalid :status: " (pr-str (:status result))
                         ", expected :ok, :skip, or :error")
                    {:action-type action-type :result result})))
  (let [action (:action result)]
    (when-not (vector? action)
      (throw (ex-info (str "install! for " action-type " result missing :action vector, got: " (pr-str action))
                      {:action-type action-type :result result})))
    (when-not (= action-type (first action))
      (throw (ex-info (str "install! for " action-type " result :action type mismatch: " (first action))
                      {:action-type action-type :result result})))))

(defn do-install!
  "Call install! and validate each result. Single call site for executing actions."
  [action-type opts items]
  (let [results (install! action-type opts items)]
    (run! #(validate-result! action-type %) results)
    results))
