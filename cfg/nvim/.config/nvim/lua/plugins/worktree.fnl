(fn loud []
  {:bg (Snacks.util.color :DiagnosticWarn)
   :fg (Snacks.util.color :Normal :bg)
   :gui :bold})

(fn dashboard-label []
  (let [info ((. (require :config.worktree) :info))]
    (when info
      {:text [{1 info.name :hl (if info.linked? :DiagnosticWarn :Comment)}]
       :align :center
       :padding 1})))

[{1 :nvim-lualine/lualine.nvim
  :opts (fn [_ opts]
          (let [worktree (require :config.worktree)]
            (table.insert opts.sections.lualine_b 1
                          {1 #(. (worktree.info) :name)
                           :cond #(not= nil (worktree.info))
                           :color #(when (. (worktree.info) :linked?) (loud))})))}
 {1 :snacks.nvim
  :opts {:dashboard {:sections [{:section :header}
                                dashboard-label
                                {:section :keys :gap 1 :padding 1}
                                {:section :startup}]}}}]
