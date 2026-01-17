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

(defn value->plist-xml
  "Convert any Clojure value to plist XML"
  [v]
  (cond
    (map? v)     (str "<dict>"
                      (apply str (for [[k val] v]
                                   (str "<key>" (name k) "</key>"
                                        (value->plist-xml val))))
                      "</dict>")
    (vector? v)  (str "<array>"
                      (apply str (map value->plist-xml v))
                      "</array>")
    (string? v)  (str "<string>" (xml-escape v) "</string>")
    (int? v)     (str "<integer>" v "</integer>")
    (float? v)   (str "<real>" v "</real>")
    (boolean? v) (if v "<true/>" "<false/>")
    :else        (str "<string>" (xml-escape v) "</string>")))

(defn map->plist-xml
  "Convert a Clojure map to plist XML string for use with defaults -array"
  [m]
  (value->plist-xml m))

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

(defn- set-default [opts domain key value]
  (let [type-flag (->defaults-type value)
        cmd (into ["defaults" "write" domain (name key) type-flag] (->defaults-args value))
        {:keys [exit err]} (a/exec! opts cmd)]
    {:label (str domain " " (name key) " = " value)
     :status (if (zero? exit) :ok :error)
     :message err}))

(defmethod a/install! :osx/defaults [_ opts items]
  (d/section "Setting OSX defaults"
             (for [[_name cfg] items
                   :let [domain (:domain cfg)
                         ;; Support both :settings map and single :key/:value
                         settings (or (:settings cfg)
                                      {(:key cfg) (:value cfg)})]
                   [key value] settings]
               (set-default opts domain key value))))
