[{1 :Olical/nfnl :ft :fennel}
 {1 :nvim-treesitter/nvim-treesitter
  :opts {:ensure_installed [:fennel]}}
 {1 :neovim/nvim-lspconfig
  :opts {:servers {:fennel_language_server {:settings {:fennel {:diagnostics {:globals [:vim]}}}}}}}]
