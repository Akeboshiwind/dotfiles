; plugins/lint.fnl
(local {: autoload} (require :nfnl.module))
(local {: update : kv-pairs : reduce : table? : get : assoc} (autoload :nfnl.core))
(local util (autoload :util))
(local lint (autoload :lint))
(local cfg (autoload :util.cfg))

[{:mason/ensure-installed [:commitlint]}

 {1 :mfussenegger/nvim-lint
  ; >> lint/by-ft ft->linter
  ; Add new linters here
  :lint/by-ft {:gitcommit [:commitlint]}
  ; >> lint/linters linter->config
  ; Linter Settings
  ; You can override the settings of a linter here
  ; You can also add linters unknown to nvim-lint
  ; An additional setting :condition is supported which only runs the linter when it returns true
  ; It is passed a single argument, a table with the keys :filename and :dirname
  ; For example, only run when the parents contain .github/workflows:
  ; (fn [{: dirname}]
  ;   (string.match dirname ".github/workflows")
  :lint/linters
  {:commitlint
   {:args ["--config"
           (.. (vim.fn.stdpath "config")
               "/config/commitlint.config.js")
           "--extends"
           (.. (vim.fn.stdpath "data")
               "/mason/packages/commitlint/node_modules/@commitlint/config-conventional")]}}
  :opts {; Event to trigger linters
         :events [:BufWritePost :BufReadPost :InsertLeave]}
  :config (fn [_ opts G]
            ; Add new linters or override existing ones
            (reduce (fn [acc [name linter]]
                      (if (and (table? linter) (get acc name))
                        (update acc name #(vim.tbl_deep_extend "force" $ linter))
                        (assoc acc name linter)))
                    lint.linters
                    (->> G.lint/linters
                         cfg.merge-all
                         kv-pairs))

            (assoc lint :linters_by_ft (cfg.merge-all G.lint/by-ft))

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
              (when (not= 0 (length names))
                (lint.try_lint names)))

            ; Add autocmd to trigger linters
            (vim.api.nvim_create_autocmd opts.events
              {:group (vim.api.nvim_create_augroup "nvim-lint" {:clear true})
               :callback (util.debounce 100 #(try-lint))}))}]
