; plugins/lang/typescript.fnl

[{1 :williamboman/mason.nvim
  :opts {:ensure-installed {:prettierd true}}}
 {1 :pmizio/typescript-tools.nvim
  :ft ["javascript" "javascriptreact"
       "typescript" "typescriptreact"]
  :dependencies [:nvim-lua/plenary.nvim
                 :neovim/nvim-lspconfig]
  :opts {}}
 {1 :stevearc/conform.nvim
  :opts {:formatters_by_ft {:javascript [:prettierd]
                            :typescript [:prettierd]}}}]
