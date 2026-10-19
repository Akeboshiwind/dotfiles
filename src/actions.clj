(ns actions
  "Action multimethod registry for dotfile management.
   Each action type (e.g. :pkg/brew) implements install! in its own namespace."
  (:require [clojure.java.io :as io]
            [clojure.string :as str]
            [babashka.process :as process]
            [display :as d]
            [outcome :as o]))

;; =============================================================================
;; Shared state
;; =============================================================================

(def ^:dynamic *cache*
  "Atom holding the current cache data. Bound during check/execute phases."
  (atom nil))

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
   Options: :prefix for output line prefix (default \"    \"),
            :env map of extra environment variables to pass to the process.
   Returns {:exit int :err string-or-nil}"
  [{:keys [prefix env] :or {prefix default-prefix}} args]
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
                  (str/replace #"\s*\n\s*" " "))))}))

;; =============================================================================
;; Helpers
;; =============================================================================

(defn simple-install
  "Helper for actions that follow the common pattern: run a command for each item.
   - action-type: the action type keyword (e.g. :pkg/brew), used for :action in results
   - opts: execution options (passed to exec!)
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

(defmulti queries
  "The set of query keys `check` reads for these declared items of a type.
   `declared` is {key opts}. A query key is a vector whose first element picks
   the `run-query` method, e.g. [:fs :link \"~/.gitconfig\"]. Pure."
  (fn [type _declared] type))

(defmethod queries :default [_ _] #{})

(defmulti manifest
  "A manifest fragment this plugin contributes beneath the user's manifest, or
   nil. The fragment is shaped like a manifest step and may name any type; the
   user's own declaration of the same [type key] replaces it."
  identity)

(defmethod manifest :default [_] nil)

(defmulti declared-identity
  "What a declared item is installed as, to compare with what its manager
   reports installed. Pure. Default: the key's name."
  (fn [type _key _opts] type))

(defmethod declared-identity :default [_ key _opts]
  (if (keyword? key) (name key) (str key)))

(defmulti extras-queries
  "The set of query keys `extras` reads for an exclusive manager. Pure."
  identity)

(defmulti extras
  "What an exclusive manager has installed that `declared`, the set of names
   the manifest declares for it, does not include: a sorted vector of
   {:name string} maps. Pure. A manager can only be declared exclusive if it
   defines this."
  (fn [manager _declared _facts] manager))

(defmulti removal-queries
  "The set of query keys `remove-extras!` reads for a manager, gathered at
   apply time. Pure."
  identity)

(defmethod removal-queries :default [_] #{})

(defmulti remove-extras!
  "Remove extras (as returned by `extras`) from a manager. Returns install!
   result maps."
  (fn [manager _opts _extras _facts] manager))

(defmulti run-query
  "Ask the machine the question a query key names, and return the answer.
   Called only by the shell (facts/gather)."
  first)

(defmulti check
  "Check whether an action is satisfied. No side effects.
   Returns a CheckOutcome (see outcome.clj).
   `facts` holds the answers to the queries `queries` declared for this type
   (see facts.clj)."
  (fn [type _key _opts _facts] type))

(defmethod check :default [_ _ _ _]
  o/unknown)

(defmulti install-queries
  "The set of query keys `install!` reads for these items of a type, gathered
   right before the batch runs. Pure."
  (fn [type _items] type))

(defmethod install-queries :default [_ _] #{})

(defmulti install!
  "Install items of a given action type.
   Dispatches on action type keyword (e.g. :pkg/brew).
   Receives [type opts items facts] where:
   - type: action keyword
   - opts: execution options
   - items: map of {name item-opts}
   - facts: a facts snapshot (see facts.clj)"
  (fn [type _opts _items _facts] type))

(defmethod install! :default [type _opts _items _facts]
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
  [action-type opts items facts]
  (let [results (install! action-type opts items facts)]
    (run! #(validate-result! action-type %) results)
    results))
