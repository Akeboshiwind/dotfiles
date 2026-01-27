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
    (let [proc (process/process args (cond-> {:err :string}
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
   - opts: execution options (passed to exec!, includes :dry-run)
   - title: section title
   - label-fn: (fn [key item-opts] -> string)
   - cmd-fn: (fn [key item-opts] -> command vector)
   - items: map of {key item-opts}"
  ([opts title cmd-fn items]
   (simple-install opts title (fn [k _] (name k)) cmd-fn items))
  ([opts title label-fn cmd-fn items]
   (d/section title
     (map (fn [[k item-opts]]
            (let [{:keys [exit err]} (exec! opts (cmd-fn k item-opts))]
              {:label (label-fn k item-opts)
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
