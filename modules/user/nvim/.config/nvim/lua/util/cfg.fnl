(local {: autoload} (require :nfnl.module))
(local {: map : filter : update : empty?} (autoload :nfnl.core))

(fn flatten-1 [coll]
  (let [t []]
    (each [_ item (ipairs coll)]
      (if (= (type item) :table)
        (icollect [_ v (ipairs item) &into t] v)
        (table.insert t item)))
    t))

(fn group-by-key [coll]
  (accumulate [G {}
               _ m (ipairs coll)]
    (accumulate [acc {}
                 k v (pairs m)]
      (let [value (or (. G k) [])]
        (table.insert value v)
        (tset G k value)
        G))))

(fn merge-into! [base coll]
  (if (empty? coll)
    base
    (vim.tbl_deep_extend :force
      base
      (unpack coll))))

(fn merge-all [coll]
  (merge-into! {} coll))

(fn ensure-table [config]
  (if (not= (type config) :table)
    [config]
    config))

(fn path->module [path]
  (-?> path
       (string.match "lua/(.+)%.lua$")
       (string.gsub "/" ".")))

(fn find-modules [module recursively?]
  (let [patt (.. "lua/"
                 (string.gsub module "%." "/")
                 (if recursively? "/**/*.lua" "/*.lua"))]
    (->> (vim.api.nvim_get_runtime_file patt true)
         (map path->module))))

(fn wrap-config [config-fn global-config]
  (if (= (type config-fn) :function)
    (fn [plugin opts]
      (config-fn plugin opts global-config))
    config-fn))

(fn plugin? [m]
  (and m (. m 1)))

(fn only [coll]
  (assert (= 1 (length coll)) (.. "expected only one value"))
  (. coll 1))

{: flatten-1
 : group-by-key
 : merge-into! : merge-all
 : ensure-table
 : path->module
 : find-modules
 : wrap-config
 : plugin?
 : only}
