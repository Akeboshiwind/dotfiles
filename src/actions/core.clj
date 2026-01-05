(ns actions.core
  "Action multimethod registry for dotfile management.
   Each action type (e.g. :pkg/brew) implements install! in its own namespace.")

;; =============================================================================
;; Multimethods
;; =============================================================================

(defmulti install!
  "Install items of a given action type.
   Dispatches on action type keyword (e.g. :pkg/brew).
   Receives [type items ctx] where:
   - type: action keyword
   - items: map of {name opts}
   - ctx: execution context (e.g. display helpers)"
  (fn [type _items _ctx] type))

(defmethod install! :default [type _items _ctx]
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
