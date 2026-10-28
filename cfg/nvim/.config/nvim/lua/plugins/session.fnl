[{1 :folke/persistence.nvim
  :init (fn []
          (vim.api.nvim_create_autocmd
            :VimEnter
            {:once true
             :callback #((. (require :config.session) :restore-on-start))})
          (vim.api.nvim_create_autocmd
            :User
            {:pattern :PersistenceSavePre
             :callback #(vim.cmd "silent! %argdelete")}))
  :keys [{1 :<leader>qr
          2 #((. (require :config.session) :reset))
          :desc "Reset Session"}]}]
