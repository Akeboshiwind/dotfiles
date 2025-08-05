; plugins/copilot.fnl
(local {: autoload} (require :nfnl.module))

[{1 :zbirenbaum/copilot-cmp
  :opts {}}
 {1 :zbirenbaum/copilot.lua
  :event :VeryLazy
  :dependencies [:zbirenbaum/copilot-cmp]
  :opts {:panel {:enabled false}
         :suggestion {:enabled false}}}]
