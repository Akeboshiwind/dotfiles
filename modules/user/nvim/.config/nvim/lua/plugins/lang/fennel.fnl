; plugins/lang/fennel.lua
(local {: autoload} (require :nfnl.module))
(local test-harness (autoload :plenary.test_harness))
(local wk (autoload :which-key))

[{:mason/ensure-installed [:fennel-language-server]
  :fold/close-kinds {:fennel [:fn_form]}
  :lsp/servers {:fennel_language_server
                {:single_file_support true
                 :settings
                 {:fennel
                  {:diagnostics {:globals [:jit :comment 
                                           ; vim
                                           :vim
                                           ; hammerspoon
                                           :hs :spoon]}
                   :workspace {:library (vim.api.nvim_list_runtime_paths)}}}}}}
 {1 :Olical/nfnl
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
  :ft ["fennel"]}]
