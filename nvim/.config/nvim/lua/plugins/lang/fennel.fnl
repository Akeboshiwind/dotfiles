; plugins/lang/fennel.lua
(local {: autoload} (require :nfnl.module))
(local {: update} (autoload :nfnl.core))
(local lspconfig (require :lspconfig))

[{1 :Olical/nfnl
  :ft "fennel"}
 {1 :Olical/conjure
  :ft ["fennel"]}
 {1 :williamboman/mason.nvim
  :opts {:ensure-installed {:fennel-language-server true}}}
 {1 :neovim/nvim-lspconfig
  :opts {:servers
         {:fennel_language_server
          {:filetypes [:fennel]
           :root_dir (lspconfig.util.root_pattern "lua" "fnl")
           :single_file_support true
           :settings
           {:fennel
            {:diagnostics {:globals [:vim :jit :comment]}
             :workspace {:library (vim.api.nvim_list_runtime_paths)}}}}}}}]
