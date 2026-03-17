(ns actions.assert
  (:require [actions :as a]
            [babashka.process :as process]
            [clojure.string :as str]
            [display :as d]
            [outcome :as o]))

(defmethod a/requires :assert [_] nil)

(defn- eval-clj
  "Evaluate a Clojure form with assert utility functions available."
  [form]
  (binding [*ns* (find-ns 'actions.assert)]
    (eval form)))

(defn- run-check
  "Run an assertion check. Returns true if passed, false if failed."
  [{:keys [path src clj]}]
  (cond
    clj  (boolean (eval-clj clj))
    path (zero? (:exit (apply process/shell {:out :string :err :string :continue true} ["bash" path])))
    src  (zero? (:exit (process/shell {:out :string :err :string :continue true} "bash" "-c" src)))))

(defmethod a/check :assert [_ key opts]
  (if-not (or (:path opts) (:src opts) (:clj opts))
    (o/error "Either :path, :src, or :clj required")
    (if (run-check opts)
      o/satisfied
      (cond-> (o/error (or (:message opts) "assertion failed"))
        (:instructions opts) (assoc :detail (:instructions opts))))))

(defmethod a/install! :assert [_ opts items]
  (d/section "Checking assertions"
    (map (fn [[k {:keys [message instructions] :as cfg}]]
           (if (run-check cfg)
             {:action [:assert k]
              :label (name k)
              :status :ok}
             {:action [:assert k]
              :label (name k)
              :status :error
              :message (or message "assertion failed")
              :detail instructions}))
         items)))
