(fn loud []
  {:bg (Snacks.util.color :DiagnosticWarn)
   :fg (Snacks.util.color :Normal :bg)
   :gui :bold})

[{1 :nvim-lualine/lualine.nvim
  :opts (fn [_ opts]
          (let [worktree (require :config.worktree)]
            (table.insert opts.sections.lualine_b 1
                          {1 #(. (worktree.info) :name)
                           :cond #(not= nil (worktree.info))
                           :color #(when (. (worktree.info) :linked?) (loud))})))}]
