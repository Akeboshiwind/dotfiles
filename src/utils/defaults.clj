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

(defn read-domain
  "Read all defaults for a domain, returning a Clojure map.
   With no args, reads the currentHost global domain."
  ([] (read-domain "-g"))
  ([domain]
   (let [{:keys [out exit]} (process/shell {:out :string :err :string :continue true}
                                           "defaults" "-currentHost" "export" domain "-")]
     (when (zero? exit)
       (let [parsed (xml/parse-str out)
             dict-node (first (filter :tag (:content parsed)))]
         (parse-dict (:content dict-node)))))))
