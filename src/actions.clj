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

(def ^:dynamic *dry-run* false)

(defn- prefix-print
  ([stream] (prefix-print "    " stream))
  ([prefix stream]
   (with-open [rdr (io/reader stream)]
     (doseq [line (line-seq rdr)]
       (println prefix (d/gray line))))))

(defn exec!
  "Execute a command. Respects *dry-run* binding.
   Options: :prefix for output line prefix (default \"    \")
   Returns {:exit int :err string-or-nil}"
  ([args]
   (exec! {} args))
  ([{:keys [prefix] :or {prefix "    "}}
    args]
   (if *dry-run*
     (do
       (println prefix (d/gray (str/join " " args)))
       {:exit 0 :err nil})
     (let [proc (process/process args {:err :string})
           out-future (future (prefix-print prefix (:out proc)))
           result @proc]
       @out-future
       {:exit (:exit result)
        :err (let [e (:err result)]
               (when (and e (seq (str/trim e)))
                 (-> e
                     str/trim
                     (str/replace #"\s*\n\s*" " "))))}))))

;; =============================================================================
;; Multimethods
;; =============================================================================

(defmulti validate
  "Validate items of a given action type.
   Returns seq of error maps {:action :key :error}, or nil if valid."
  (fn [type _items] type))

(defmethod validate :default [_ _] nil)

(defmulti install!
  "Install items of a given action type.
   Dispatches on action type keyword (e.g. :pkg/brew).
   Receives [type items] where:
   - type: action keyword
   - items: map of {name opts}"
  (fn [type _items] type))

(defmethod install! :default [type _items]
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
