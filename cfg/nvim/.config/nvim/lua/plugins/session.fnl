[{1 :folke/persistence.nvim
  :init (fn []
          (vim.api.nvim_create_autocmd
            :VimEnter
            {:once true
             :callback #((. (require :config.session) :restore-on-start))}))}]
