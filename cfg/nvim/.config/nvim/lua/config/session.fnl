(fn bare-start? []
  (and (= 0 (vim.fn.argc -1))
       (= "" (vim.api.nvim_buf_get_name 0))
       (vim.deep_equal [""] (vim.api.nvim_buf_get_lines 0 0 -1 false))
       (< 0 (length (vim.api.nvim_list_uis)))))

(fn restore-on-start []
  "For VimEnter: decides from the startup state, then loads outside the autocmd,
  where did_filetype() is already set and :setfiletype would skip every restored buffer."
  (when (bare-start?)
    (vim.schedule (. (require :persistence) :load))))

{: restore-on-start}
