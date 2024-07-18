; plugins/format.fnl
(local {: autoload} (require :nfnl.module))
(local conform (autoload :conform))

[{1 :stevearc/conform.nvim
  :event [:BufWritePre]
  :cmd [:ConformInfo]
  :keys [{1 "<leader>F" 2 #(conform.format) :desc "Format buffer"}]
  :opts {:formatters_by_ft {}
         :formatters {}}}]
