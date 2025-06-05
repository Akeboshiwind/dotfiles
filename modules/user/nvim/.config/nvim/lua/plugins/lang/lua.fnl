; plugins/lang/lua.fnl
(local {: autoload} (require :nfnl.module))
(local {: update} (autoload :nfnl.core))

[{1 :williamboman/mason.nvim
  :opts {:ensure-installed {:stylua true}}}
 {1 :stevearc/conform.nvim
  :opts {:formatters_by_ft {:lua ["stylua"]}
         :formatters {:stylua {:prepend_args ["--config-path"
                                              (.. (vim.fn.stdpath "config")
                                                  "/config/stylua.toml")]}}}}]
