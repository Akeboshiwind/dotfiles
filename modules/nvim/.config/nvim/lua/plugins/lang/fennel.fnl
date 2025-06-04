; plugins/lang/fennel.lua
(local {: autoload} (require :nfnl.module))
(local lspconfig (autoload :lspconfig))
(local test-harness (autoload :plenary.test_harness))
(local wk (autoload :which-key))


[{1 :Olical/nfnl
  :ft "fennel"
  :config (fn [_ _opts]
            (fn test-current-file []
              (let [path (vim.fn.expand "%")
                    lua-path (path:gsub ".fnl$" ".lua")]
                (vim.cmd (.. ":PlenaryBustedFile " lua-path))
                (test-harness.test_file lua-path)))
              
            (wk.add
              [{1 "<leader>p" :group "plenary"}
               {1 "<leader>pt" 2 test-current-file :desc "Test current file"}]))}
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
            {:diagnostics {:globals [:jit :comment 
                                     ; vim
                                     :vim
                                     ; hammerspoon
                                     :hs :spoon]}
             :workspace {:library (vim.api.nvim_list_runtime_paths)}}}}}}}]
