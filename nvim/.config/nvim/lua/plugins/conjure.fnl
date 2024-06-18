; plugins/conjure.fnl

[{1 :PaterJason/cmp-conjure
  :dependencies [:hrsh7th/nvim-cmp]}
 {1 :folke/which-key.nvim
  :opts {:defaults
         ; TODO: These don't work, why?
         {"<leader>l" {:name "log"}
          "<leader>e" {:name "eval"}
          "<leader>c" {:name "display as comment"}
          "<leader>g" {:name "goto"}}}}
 {1 :Olical/conjure
  :version "*"
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
              (tset vim.g (string.format "conjure#%s" k) v)))}]
