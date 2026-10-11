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

(fn file-buffer? [buf]
  (vim.tbl_contains ["" :acwrite] (. vim.bo buf :buftype)))

(fn unsaved-buffers []
  (icollect [_ buf (ipairs (vim.api.nvim_list_bufs))]
    (when (and (file-buffer? buf) (. vim.bo buf :modified))
      (let [name (vim.api.nvim_buf_get_name buf)]
        (if (= "" name) "[No Name]" (vim.fn.fnamemodify name ":~:."))))))

(fn clear []
  "Closes every tab, window, listed buffer and terminal, and stops every LSP client.
  Plugins' own unlisted buffers are left alone.
  Returns false, closing nothing, while a file buffer has unsaved changes."
  (let [unsaved (unsaved-buffers)]
    (if (< 0 (length unsaved))
        (do
          (vim.notify (.. "Unsaved changes in:\n" (table.concat unsaved "\n")) vim.log.levels.WARN)
          false)
        (do
          (each [_ client (ipairs (vim.lsp.get_clients))]
            (client:stop))
          (vim.cmd "silent! tabonly | silent! only")
          (each [_ buf (ipairs (vim.api.nvim_list_bufs))]
            (when (or (. vim.bo buf :buflisted) (= :terminal (. vim.bo buf :buftype)))
              (vim.api.nvim_buf_delete buf {:force true})))
          true))))

(fn reset []
  "Back to the dashboard, with the cwd's session file deleted so the next start doesn't restore it."
  (when (clear)
    (vim.fn.delete ((. (require :persistence) :current)))
    (Snacks.dashboard)))

{: restore-on-start : clear : reset}
