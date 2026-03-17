(ns actions.osx
  (:require [clojure.string :as str]
            [babashka.process :as process]
            [actions :as a]
            [display :as d]
            [outcome :as o]))

(defmethod a/requires :osx/defaults [_] nil)

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

(defn- set-default [opts config-name domain key value]
  (let [type-flag (->defaults-type value)
        cmd (into ["defaults" "write" domain (name key) type-flag] (->defaults-args value))
        {:keys [exit err]} (a/exec! opts cmd)]
    {:action [:osx/defaults config-name]
     :label (str domain " " (name key) " = " value)
     :status (if (zero? exit) :ok :error)
     :message err}))

(defn- defaults-value-matches?
  "Compare expected value against `defaults read` output string."
  [expected actual-str]
  (let [actual (str/trim actual-str)]
    (cond
      (boolean? expected) (= (if expected "1" "0") actual)
      (int? expected)     (= expected (parse-long actual))
      (float? expected)   (= expected (parse-double actual))
      (string? expected)  (= expected actual)
      ;; TODO: support complex types (arrays, dicts) via utils.defaults/read-domain
      :else               true)))

(defmethod a/check :osx/defaults [_ key opts]
  (let [domain   (:domain opts)
        settings (or (:settings opts)
                     {(:key opts) (:value opts)})]
    (reduce (fn [acc [k value]]
              (if (or (map? value) (vector? value))
                acc
                (let [{:keys [exit out]} (process/shell {:out :string :err :string :continue true}
                                                        "defaults" "read" domain (name k))]
                  (cond
                    (not (zero? exit))                       (reduced (o/drift :wrong))
                    (not (defaults-value-matches? value out)) (reduced (o/drift :wrong))
                    :else                                    acc))))
            o/satisfied
            settings)))

(defmethod a/install! :osx/defaults [_ opts items]
  (d/section "Setting OSX defaults"
             (for [[config-name cfg] items
                   :let [domain (:domain cfg)
                         settings (or (:settings cfg)
                                      {(:key cfg) (:value cfg)})
                         results (mapv (fn [[key value]]
                                         (set-default opts config-name domain key value))
                                       settings)
                         failed (first (filter #(= :error (:status %)) results))]]
               ;; Return one aggregate result per config-name
               (if failed
                 (assoc failed :label (name config-name))
                 {:action [:osx/defaults config-name]
                  :label (name config-name)
                  :status :ok}))))
