; plugins/lang/lua.fnl
(local {: autoload} (require :nfnl.module))
(local {: update} (autoload :nfnl.core))

[{1 :williamboman/mason.nvim
  :opts (fn [_ opts]
          (-> opts
              (update :ensure-installed #(or $ []))
              (update :ensure-installed
                #(vim.list_extend $ ["stylua"]))))}
 {1 :stevearc/conform.nvim
  :opts {:formatters_by_ft {:lua ["stylua"]}
         :formatters {:stylua {:prepend_args ["--config-path"
                                              (.. (vim.fn.stdpath "config")
                                                  "/config/stylua.toml")]}}}}]
