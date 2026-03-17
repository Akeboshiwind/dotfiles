(ns utils.defaults
  (:require [babashka.process :as process]
            [clojure.data.xml :as xml]))

(declare parse-node)

(defn- parse-dict [children]
  (let [elems (filter :tag children)
        pairs (partition 2 elems)]
    (into {} (map (fn [[k v]]
                    [(first (:content k)) (parse-node v)])
                  pairs))))

(defn- parse-array [children]
  (mapv parse-node (filter :tag children)))

(defn- parse-node [{:keys [tag content]}]
  (case tag
    :dict    (parse-dict content)
    :array   (parse-array content)
    :string  (apply str content)
    :integer (parse-long (apply str content))
    :real    (parse-double (apply str content))
    :true    true
    :false   false
    :data    (apply str content)
    :date    (apply str content)
    nil))

(defn- parse-plist-xml [xml-str]
  (let [parsed (xml/parse-str xml-str)
        dict-node (first (filter :tag (:content parsed)))]
    (parse-dict (:content dict-node))))

(defn read-domain
  "Read all defaults for a domain, returning a Clojure map.
   With no args, reads the currentHost global domain."
  ([]
   (let [{:keys [out exit]} (process/shell {:out :string :err :string :continue true}
                                           "defaults" "-currentHost" "export" "-g" "-")]
     (when (zero? exit)
       (parse-plist-xml out))))
  ([domain]
   (let [{:keys [out exit]} (process/shell {:out :string :err :string :continue true}
                                           "defaults" "export" domain "-")]
     (when (zero? exit)
       (parse-plist-xml out)))))
