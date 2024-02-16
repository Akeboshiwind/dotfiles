; plugins/lang/python.fnl
(local {: autoload} (require :nfnl.module))
(local {: update} (autoload :nfnl.core))

[{1 :williamboman/mason.nvim
  :opts (fn [_ opts]
          (-> opts
              (update :ensure-installed #(or $ []))
              (update :ensure-installed
                #(vim.list_extend $ ["black" "isort"]))))}
 {1 :stevearc/conform.nvim
  :opts {:formatters_by_ft {:python ["black" "isort"]}}}
 {1 :neovim/nvim-lspconfig
  :opts {:servers {:pylsp {}}}}]
