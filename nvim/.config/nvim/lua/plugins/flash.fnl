; plugins/flash.fnl
(local {: autoload} (require :nfnl.module))
(local flash (autoload :flash))

[{1 :folke/flash.nvim
  :event :VeryLazy
  :opts {:modes {:char {; So that `fd` still works as <esc>
                        ; TODO: Is there another method?
                        :keys [(comment :f) :F
                               :t :T]
                        ; Only move one
                        :autohide true
                        :multi_line false
                        :highlight {:backdrop false}}}}
  :keys [{1 "s" 2 #(flash.jump)
          :mode [:n :x :o]
          :desc "Flash"}
         {1 "S" 2 #(flash.treesitter)
          :mode [:n :x :o]
          :desc "Flash Treesitter"}
         {1 "r" 2 #(flash.remote)
          :mode :o
          :desc "Remote Flash"}
         {1 "R" 2 #(flash.treesitter_search)
          :mode [:o :x]
          :desc "Treesitter Search"}
         {1 "<c-s>" 2 #(flash.toggle)
          :mode [:c]
          :desc "Toggle Flash Search"}]}]

