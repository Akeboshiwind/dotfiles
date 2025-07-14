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
                            :typescript [:prettierd]}}}
 {1 :kevinhwang91/nvim-ufo
  :opts
  {:fold-queries
   {:typescript
     "(call_expression
       function: (identifier) @_fn
       (#match? @_fn \"^(test|it|beforeEach|afterEach)$\")) @fold.test"}
   :close-kinds {:typescript [:function_declaration
                              :method_definition
                              :generator_function_declaration]}}}]
