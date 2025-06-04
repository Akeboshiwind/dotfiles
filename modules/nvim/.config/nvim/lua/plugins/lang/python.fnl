; plugins/lang/python.fnl
(local {: autoload} (require :nfnl.module))
(local {: update} (autoload :nfnl.core))

[{1 :williamboman/mason.nvim
  :opts {:ensure-installed {:black true
                            :isort true}}}
 {1 :stevearc/conform.nvim
  :opts {:formatters_by_ft {:python ["black" "isort"]}}}
 {1 :neovim/nvim-lspconfig
  :opts {:servers {:pylsp {}}}}]
