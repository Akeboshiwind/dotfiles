; plugins/lang/python.fnl

[{1 :williamboman/mason.nvim
  :opts (fn [_ opts]
          (set opts.ensure_installed (or opts.ensure_installed {}))
          (vim.list_extend opts.ensure_installed ["black" "isort"]))}
 {1 :stevearc/conform.nvim
  :opts {:formatters_by_ft {:python ["black" "isort"]}}}
 {1 :neovim/nvim-lspconfig
  :opts {:servers {:pylsp {}}}}]
