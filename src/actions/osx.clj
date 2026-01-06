(ns actions.osx
  (:require [clojure.string :as str]
            [actions :as a]
            [display :as d]))

(defn- xml-escape [s]
  (-> (str s)
      (str/replace "&" "&amp;")
      (str/replace "<" "&lt;")
      (str/replace ">" "&gt;")
      (str/replace "\"" "&quot;")))

(defn map->plist-xml
  "Convert a Clojure map to plist XML string for use with defaults -array"
  [m]
  (str "<dict>"
       (apply str
              (for [[k v] m]
                (str "<key>" (name k) "</key>"
                     (cond
                       (string? v) (str "<string>" (xml-escape v) "</string>")
                       (int? v) (str "<integer>" v "</integer>")
                       (float? v) (str "<real>" v "</real>")
                       (boolean? v) (if v "<true/>" "<false/>")
                       :else (str "<string>" (xml-escape v) "</string>")))))
       "</dict>"))

(defn- ->defaults-type [value]
  (cond
    (boolean? value) "-bool"
    (int? value) "-int"
    (float? value) "-float"
    (vector? value) "-array"
    (map? value) "-dict"
    :else "-string"))

(defn- ->defaults-args
  "Convert a value to the appropriate arguments for defaults command"
  [value]
  (cond
    (vector? value) (mapv #(if (map? %) (map->plist-xml %) (str %)) value)
    (map? value) (vec (mapcat (fn [[k v]] [(name k) (str v)]) value))
    :else [value]))

(defn- set-default [domain key value]
  (let [type-flag (->defaults-type value)
        cmd (into ["defaults" "write" domain (name key) type-flag] (->defaults-args value))
        {:keys [exit]} (a/exec! cmd)]
    {:label (str domain " " (name key) " = " value)
     :status (if (zero? exit) :ok :error)}))

(defmethod a/install! :osx/defaults [_ items]
  (d/section "Setting OSX defaults"
             (for [[domain settings] items
                   [key value] settings]
               (set-default domain key value))))
