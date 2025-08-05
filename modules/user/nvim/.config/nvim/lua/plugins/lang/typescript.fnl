; plugins/lang/typescript.fnl

[{:format/by-ft {:javascript [:prettierd]
                 :typescript [:prettierd]}
  :fold/queries
  {:typescript
    "(call_expression
      function: (identifier) @_fn
      (#match? @_fn \"^(test|it|beforeEach|afterEach)$\")) @fold.test"}
  :fold/close-kinds
  {:typescript [:function_declaration
                :method_definition
                :generator_function_declaration]}
  :mason/ensure-installed [:prettierd]}
 {1 :pmizio/typescript-tools.nvim
  :ft ["javascript" "javascriptreact"
       "typescript" "typescriptreact"]
  :dependencies [:nvim-lua/plenary.nvim
                 :neovim/nvim-lspconfig]
  :opts {}}]
