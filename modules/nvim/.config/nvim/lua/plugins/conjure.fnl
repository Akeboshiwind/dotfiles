; plugins/conjure.fnl
(local {: autoload} (require :nfnl.module))
(local wk (autoload :which-key))

[{1 :PaterJason/cmp-conjure
  :dependencies [:hrsh7th/nvim-cmp]}
 {1 :Olical/conjure
  ;:version "*"
  :branch "main"
  :ft ["python"]
  :dependencies [:PaterJason/cmp-conjure]
  :opts {:config
         {"mapping#prefix" "<leader>"
          "client#clojure#nrepl#refresh#backend" "clj-reload"
          ; Briefly highlight evaluated forms
          "highlight#enabled" true}}
  :config (fn [_ opts]
            ; >> Configure
            (each [k v (pairs opts.config)]
              (tset vim.g (string.format "conjure#%s" k) v))
            ; >> Which-key groups
            (wk.add
              [{1 "<leader>c" :group "display as comment"}
               {1 "<leader>e" :group "eval"}
               {1 "<leader>g" :group "goto"}
               {1 "<leader>l" :group "log"}
               {1 "<leader>r" :group "refresh"}
               {1 "<leader>s" :group "session"}
               {1 "<leader>t" :group "test"}
               {1 "<leader>v" :group "view"}]))}]
