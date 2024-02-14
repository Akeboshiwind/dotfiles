; plugins/lint.fnl
(local util (require "util"))

[{1 :williamboman/mason.nvim
  :opts (fn [_ opts]
          (set opts.ensure_installed (or opts.ensure_installed {}))
          (vim.list_extend opts.ensure_installed ["commitlint"])
          opts)}

 {1 :mfussenegger/nvim-lint
  :opts {; Event to trigger linters
         :events [:BufWritePost :BufReadPost :InsertLeave]
         :linters_by_ft {:gitcommit ["commitlint"]}
         ; Add new linters or override existing ones
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

              ; Add autocmd to trigger linters
              (vim.api.nvim_create_autocmd opts.events
                {:group (vim.api.nvim_create_augroup "nvim-lint" {:clear true})
                 :callback (util.debounce 100 #(lint.try_lint))})))}]
