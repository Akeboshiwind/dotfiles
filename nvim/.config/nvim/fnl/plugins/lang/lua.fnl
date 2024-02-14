; plugins/lang/lua.fnl

[{1 :williamboman/mason.nvim
  :opts (fn [_ opts]
          (set opts.ensure_installed (or opts.ensure_installed {}))
          (vim.list_extend opts.ensure_installed ["stylua"]))}
 {1 :stevearc/conform.nvim
  :opts {:formatters_by_ft {:lua ["stylua"]}
         :formatters {:stylua {:prepend_args ["--config-path"
                                              (.. (vim.fn.stdpath "config")
                                                  "/config/stylua.toml")]}}}}]
