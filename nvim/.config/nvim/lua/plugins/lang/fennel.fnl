; plugins/lang/fennel.lua
(local {: autoload} (require :nfnl.module))
(local {: update} (autoload :nfnl.core))
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
              
            (wk.register
              {"p" {:name "plenary"
                    "t" [test-current-file "Test current file"]}}
              {:prefix "<leader>"}))}
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
