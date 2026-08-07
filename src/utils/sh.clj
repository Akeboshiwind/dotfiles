(ns utils.sh
  (:require [babashka.process :as process]))

(def ^:dynamic *live-queries?*
  "Whether a query may read the real machine. The test task binds this false:
   a query reaching the machine under test has escaped the cache that was
   meant to answer it, and would otherwise report the developer's own box."
  true)

(defn query!
  "Run a read-only command and return its process result. The single place
   this codebase asks the machine what is installed on it.

   `label` names the fn performing the query, so a test that has not stubbed
   it is told what to stub. Opts merge over {:out :string :err :string};
   pass {:continue true} to tolerate a non-zero exit."
  ([label args] (query! label {} args))
  ([label opts args]
   (when-not *live-queries?*
     (throw (ex-info (str "unstubbed query: " label
                          " — stub it, or the cache var that wraps it")
                     {:label label :args args})))
   (apply process/shell (merge {:out :string :err :string} opts) args)))
