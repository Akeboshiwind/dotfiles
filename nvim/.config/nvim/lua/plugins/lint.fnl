; plugins/lint.fnl
(local {: autoload} (require :nfnl.module))
(local util (autoload "util"))
(local {: update : merge} (autoload :nfnl.core))

[{1 :williamboman/mason.nvim
  :opts (fn [_ opts]
          (-> opts
              (update :ensure-installed #(or $ []))
              (update :ensure-installed
                #(vim.list_extend $ ["commitlint"]))))}

 {1 :mfussenegger/nvim-lint
  :opts {; Event to trigger linters
         :events [:BufWritePost :BufReadPost :InsertLeave]
         :linters_by_ft {:gitcommit ["commitlint"]}
         ; Add new linters or override existing ones
         ; You can also add a :condition key to add the linter only when the condition is true
         :linters {:commitlint {:args ["--config"
                                       (.. (vim.fn.stdpath "config")
                                           "/config/commitlint.config.js")
                                       "--extends"
                                       (.. (vim.fn.stdpath "data")
                                           "/mason/packages/commitlint/node_modules/@commitlint/config-conventional")]}}}
  :config (fn [_ opts]
            (let [lint (require "lint")]
              ; Add new linters or override existing ones
              (each [name linter (pairs opts.linters)]
                (if (and (= "table" (type linter))
                         (= "table" (type (. lint.linters name))))
                  (tset lint.linters name
                       (vim.tbl_deep_extend "force" (. lint.linters name) linter))
                  (tset lint.linters name linter)))

              (set lint.linters_by_ft opts.linters_by_ft)

              ; src: https://github.com/LazyVim/LazyVim/blob/a50f92f7550fb6e9f21c0852e6cb190e6fcd50f5/lua/lazyvim/plugins/linting.lua#L55
              ; Same as all of this tbh 😅
              (fn try-lint []
                ; Use nvim-lint's logic
                (var names (lint._resolve_linter_by_ft vim.bo.filetype))

                ; Add fallback linters
                (if (not= 0 (length names))
                  (vim.list_extend names (or (. lint.linters_by_ft "_") [])))

                ; Add global linters
                (vim.list_extend names (or (. lint.linters_by_ft "*") []))

                ; Filter out linters that don't match the :condition
                (let [filename (vim.api.nvim_buf_get_name 0)
                      ctx {:filename filename
                           :dirname (vim.fn.fnamemodify filename ":h")}]
                  (set names (vim.tbl_filter
                               (fn [name]
                                 (let [linter (. lint.linters name)]
                                   (and linter
                                        (not (and (= (type linter) "table")
                                                  linter.condition
                                                  (not (linter.condition ctx)))))))
                               names)))

                ; Run the linters
                (if (not= 0 (length names))
                  (lint.try_lint names)))
                                     

              ; Add autocmd to trigger linters
              (vim.api.nvim_create_autocmd opts.events
                {:group (vim.api.nvim_create_augroup "nvim-lint" {:clear true})
                 :callback (util.debounce 100 #(try_lint))})))}]
