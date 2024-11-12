; plugins/copilot.fnl
(local {: autoload} (require :nfnl.module))
(local copilot (autoload :copilot))
(local copilot-cmd (autoload :copilot.command))

[{1 :zbirenbaum/copilot-cmp
  :opts {}}
 {1 :zbirenbaum/copilot.lua
  :event :VeryLazy
  :dependencies [:zbirenbaum/copilot-cmp]
  :config (fn []
            (copilot.setup
              {:panel {:enabled false}
               :suggestion {:enabled false}})
            ; Disable by default
            ; Enable using `:Copilot enable`
            ; TODO: Fix that this prints `[Copilot] Offline` on startup
            (copilot-cmd.disable))}]
