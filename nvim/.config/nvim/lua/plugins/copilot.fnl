; plugins/copilot.fnl

[{1 :zbirenbaum/copilot-cmp
  :config #((. (require "copilot_cmp") :setup))}
 {1 :zbirenbaum/copilot.lua
  :event :VeryLazy
  :dependencies [:zbirenbaum/copilot-cmp]
  :opts {:panel {:enabled false}
         :suggestion {:enabled false}}}]
