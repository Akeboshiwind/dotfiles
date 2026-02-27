(ns actions.assert
  (:require [actions :as a]
            [display :as d]))

(defmethod a/requires :assert [_] nil)

(defmethod a/validate :assert [_ items]
  (for [[k opts] items
        :when (not (or (:path opts) (:src opts)))]
    {:action :assert
     :key k
     :error "Either :path or :src required"}))

(defmethod a/install! :assert [_ opts items]
  (d/section "Checking assertions"
    (map (fn [[k {:keys [path src message instructions]}]]
           (let [cmd (cond
                       path ["bash" path]
                       src  ["bash" "-c" src]
                       :else (throw (ex-info "Assert must have :path or :src"
                                             {:key k})))
                 ;; Always run checks — they're read-only predicates, safe in dry-run
                 {:keys [exit]} (a/exec! (dissoc opts :dry-run) cmd)]
             (if (zero? exit)
               {:action [:assert k]
                :label (name k)
                :status :ok}
               {:action [:assert k]
                :label (name k)
                :status :error
                :message (or message "assertion failed")
                :detail instructions})))
         items)))
