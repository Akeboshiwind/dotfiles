; plugins/copilot.fnl
(local {: autoload} (require :nfnl.module))
(local copilot-cmp (autoload :copilot_cmp))

[{1 :zbirenbaum/copilot-cmp
  :config #(copilot-cmp.setup)}
 {1 :zbirenbaum/copilot.lua
  :event :VeryLazy
  :dependencies [:zbirenbaum/copilot-cmp]
  :opts {:panel {:enabled false}
         :suggestion {:enabled false}}}]
