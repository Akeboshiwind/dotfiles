(ns actions.osx
  (:require [actions.core :as a]
            [display :as d]))

(defn- map->plist-xml
  "Convert a Clojure map to plist XML string for use with defaults -array"
  [m]
  (str "<dict>"
       (apply str
              (for [[k v] m]
                (str "<key>" (name k) "</key>"
                     (cond
                       (string? v) (str "<string>" v "</string>")
                       (int? v) (str "<integer>" v "</integer>")
                       (float? v) (str "<real>" v "</real>")
                       (boolean? v) (if v "<true/>" "<false/>")
                       :else (str "<string>" v "</string>")))))
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

(defmethod a/install! :osx/defaults [_ items]
  (try
    (println " ┌─ Setting OSX Defaults")
    (doseq [[domain settings] items]
      (println " ├─┬──" domain)
      (doseq [[idx [key value]] (zipmap (range) settings)]
        (let [last? (= idx (dec (count settings)))
              type-flag (->defaults-type value)
              cmd (into ["defaults" "write" domain (name key) type-flag] (->defaults-args value))
              {:keys [exit]} (a/exec! {:prefix " │ │"} cmd)]
          (println (if last? " │ └─" " │ ├─")
                   key value (if (zero? exit) (d/green "✓") (d/red "✗"))))))
    (catch Exception _
      (println " └─" (d/red "✗"))))
  (println " └─" (d/green "✓")))
