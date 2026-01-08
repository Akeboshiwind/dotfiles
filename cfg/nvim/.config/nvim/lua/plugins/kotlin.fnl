[; Requires building and installing kotlin adapter from source
 {1 :nvim-neotest/neotest
  :dependencies [{1 :ake-forks/neotest-kotlin :branch "v2.0.0-backticks-fix"}]
  :opts {:adapters {:neotest-kotlin {}}}}

 ; Use JetBrains' kotlin-lsp instead of fwcd/kotlin-language-server
 {1 :neovim/nvim-lspconfig
  :opts {:servers {:kotlin_language_server {:enabled false}
                   :kotlin_lsp {}}}}]
