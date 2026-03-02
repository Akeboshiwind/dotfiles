(ns actions.assert
  (:require [actions :as a]
            [babashka.process :as process]
            [display :as d]
            [outcome :as o]))

(defmethod a/requires :assert [_] nil)

(defmethod a/check :assert [_ key opts]
  (let [{:keys [path src]} opts]
    (if-not (or path src)
      (o/error "Either :path or :src required")
      (let [cmd (if path ["bash" path] ["bash" "-c" src])
            result (apply process/shell {:out :string :err :string :continue true} cmd)]
        (if (zero? (:exit result))
          o/satisfied
          (cond-> (o/error (or (:message opts) "assertion failed"))
            (:instructions opts) (assoc :detail (:instructions opts))))))))

(defmethod a/install! :assert [_ opts items]
  (d/section "Checking assertions"
    (map (fn [[k {:keys [path src message instructions]}]]
           (let [cmd (cond
                       path ["bash" path]
                       src  ["bash" "-c" src]
                       :else (throw (ex-info "Assert must have :path or :src"
                                             {:key k})))
                 {:keys [exit]} (a/exec! opts cmd)]
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
