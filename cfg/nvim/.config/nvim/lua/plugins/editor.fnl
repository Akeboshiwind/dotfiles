(let [telescope-actions (require :telescope.actions)]
  [{1 :nvim-telescope/telescope.nvim
    :opts {:defaults {:mappings {:i {"<C-j>" (fn [...] (telescope-actions.move_selection_next ...))
                                     "<C-k>" (fn [...] (telescope-actions.move_selection_previous ...))
                                     "<C-h>" (fn [...] (telescope-actions.which_key ...))}}}}}])
