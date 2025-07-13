; plugins/fold.fnl
(local {: autoload} (require :nfnl.module))
(local ufo (autoload :ufo))

[{1 :kevinhwang91/nvim-ufo
  :dependencies [:kevinhwang91/promise-async]
  :lazy false
  :config (fn []
            (set vim.opt.foldenable true)

            ;; How folds look
            (set vim.opt.foldcolumn "0") ; disable
            ;(set vim.opt.foldtext "") ; show the first line syntax highlighted
            ;; How folds work
            (set vim.opt.foldlevel 99) ; Let ufo control closing
            (set vim.opt.foldlevelstart 99) ; Let ufo control closing
            ;(set vim.opt.foldnestmax 4) ; max nesting
            (set vim.opt.foldopen "") ; disable vim auto-opening folds (e.g. '[' and search)

            (ufo.setup
              {:provider_selector
               (fn [_bufnr _filetype _buftype]
                 [:treesitter :indent])
               :open_fold_hl_timeout 100
               :close_fold_kinds_for_ft
               {:default [:function_definition
                          :function_declaration
                          :method_definition]}}))
  :keys [{1 "zR" 2 #(ufo.openAllFolds)
          :mode [:n]
          :desc "Open All Folds"}
         {1 "zM" 2 #(ufo.closeAllFolds)
          :mode [:n]
          :desc "Close All Folds"}]}]
