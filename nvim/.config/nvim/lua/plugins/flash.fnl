; plugins/flash.fnl
(local {: autoload} (require :nfnl.module))
(local flash (autoload :flash))

[{1 :folke/flash.nvim
  :event :VeryLazy
  :opts {:modes {:char {:keys [; So that `fd` still works as <esc>
                               ; TODO: Is there another method?
                               (comment :f) :F
                               :t :T]}}}
  :keys [{1 "s" 2 #(flash.jump)
          :mode [:n :x :o]
          :desc "Flash"}
         {1 "S" 2 #(flash.treesitter)
          :mode [:n :x :o]
          :desc "Flash Treesitter"}
         {1 "*" 2 #(flash.jump {:pattern (vim.fn.expand "<cword>")
                                :jump {:history true
                                       :register true
                                       :jumplist true}})
          :mode [:n :x :o]
          :desc "Flash under cursor"}
         {1 "r" 2 #(flash.remote)
          :mode "o"
          :desc "Remote Flash"}
         {1 "R" 2 #(flash.treesitter_search)
          :mode [:o :x]
          :desc "Treesitter Search"}
         {1 "<c-s>" 2 #(flash.toggle)
          :mode [:c]
          :desc "Toggle Flash Search"}]}]

