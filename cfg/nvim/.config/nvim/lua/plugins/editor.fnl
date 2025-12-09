(let [telescope-actions (require :telescope.actions)]
  [{1 :chrisgrieser/nvim-spider
    :keys [{1 :w 2 "<cmd>lua require('spider').motion('w')<CR>" :mode [:n :o :x]}
           {1 :e 2 "<cmd>lua require('spider').motion('e')<CR>" :mode [:n :o :x]}
           {1 :b 2 "<cmd>lua require('spider').motion('b')<CR>" :mode [:n :o :x]}]}
   {1 :nvim-telescope/telescope.nvim
    :opts {:defaults {:mappings {:i {"<C-j>" (fn [...] (telescope-actions.move_selection_next ...))
                                     "<C-k>" (fn [...] (telescope-actions.move_selection_previous ...))
                                     "<C-h>" (fn [...] (telescope-actions.which_key ...))}}}}}])
