(ns outcome
  "CheckOutcome data type — the result of checking whether an action is satisfied.")

;; CheckOutcome is a map with :outcome key and optional :kind/:message fields.

;; Constructors

(def satisfied
  "Action is already in desired state."
  {:outcome :satisfied})

(defn drift
  "Action needs to be applied. kind describes what changed."
  [kind]
  {:outcome :drift :kind kind})

(def unknown
  "Cannot determine state — will attempt install."
  {:outcome :unknown})

(defn conflict
  "Action cannot proceed — manual intervention needed."
  [msg]
  {:outcome :conflict :message msg})

(defn error
  "Check itself failed (e.g. validation error, script crash)."
  [msg]
  {:outcome :error :message msg})

(def cancelled
  "Cancelled because a dependency failed."
  {:outcome :cancelled})

;; Predicates

(defn satisfied? [o] (= :satisfied (:outcome o)))
(defn drift?     [o] (= :drift (:outcome o)))
(defn unknown?   [o] (= :unknown (:outcome o)))
(defn conflict?  [o] (= :conflict (:outcome o)))
(defn error?     [o] (= :error (:outcome o)))
(defn cancelled? [o] (= :cancelled (:outcome o)))

(defn actionable?
  "Should this outcome trigger an install? (drift or unknown)"
  [o]
  (#{:drift :unknown} (:outcome o)))

(defn blocking?
  "Does this outcome block downstream dependents? (error, conflict, cancelled)"
  [o]
  (#{:error :conflict :cancelled} (:outcome o)))

;; Legacy bridge

(defn from-legacy-state
  "Convert a legacy status keyword to a CheckOutcome."
  [state]
  (case state
    :installed satisfied
    :missing   (drift :missing)
    :outdated  (drift :outdated)
    :wrong     (drift :wrong)
    :orphan    (drift :orphan)
    :unknown   unknown))
