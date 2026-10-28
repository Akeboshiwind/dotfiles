(local h (dofile (.. (vim.fs.dirname (vim.fs.abspath (. arg 0))) "/harness.lua")))

(fn save-session [dir file]
  (h.stop (h.start dir [file])))

(h.run
  [["a bare start restores the cwd's session"
    (fn []
      (let [dir (h.project [:a.txt])]
        (save-session dir :a.txt)
        (let [nvim (h.start dir)
              restored? (h.wait-until #(h.ends-with? (. (h.current nvim) :name) :/a.txt))
              buf (h.current nvim)
              filetypes (h.buffer-filetypes nvim)]
          (h.stop nvim)
          (h.check restored? (.. "expected a.txt, got " (vim.inspect buf)))
          (h.check (= buf.filetype :text)
                   (.. "restored buffer skipped FileType: " (vim.inspect buf)))
          (h.check (not (vim.tbl_contains filetypes :snacks_dashboard))
                   (.. "dashboard outlived the restore: " (vim.inspect filetypes))))))]

   ["a bare start without a session shows the dashboard"
    (fn []
      (let [nvim (h.start (h.project [:a.txt]))
            dashboard? (h.wait-until #(= (. (h.current nvim) :filetype) :snacks_dashboard))
            buf (h.current nvim)]
        (h.stop nvim)
        (h.check dashboard? (.. "expected the dashboard, got " (vim.inspect buf)))))]

   ["a start with a file argument opens only that file"
    (fn []
      (let [dir (h.project [:a.txt :b.txt])]
        (save-session dir :a.txt)
        (let [nvim (h.start dir [:b.txt])
              names (h.buffer-names nvim)]
          (h.stop nvim)
          (h.check (not (h.has-buffer? names :/a.txt))
                   (.. "session leaked into an explicit start: " (vim.inspect names))))))]

   ["a file closed after starting with it as an argument stays closed in the session"
    (fn []
      (let [dir (h.project [:a.txt :b.txt])
            nvim (h.start dir [:b.txt])]
        (h.exec-lua nvim "vim.cmd('edit a.txt | bdelete b.txt')")
        (h.stop nvim)
        (let [nvim (h.start dir)
              _ (h.wait-until #(h.ends-with? (. (h.current nvim) :name) :/a.txt))
              listed (h.exec-lua nvim "return vim.tbl_map(vim.api.nvim_buf_get_name, vim.tbl_filter(function(b) return vim.bo[b].buflisted end, vim.api.nvim_list_bufs()))")]
          (h.stop nvim)
          (h.check (not (h.has-buffer? listed :/b.txt))
                   (.. "the closed file came back: " (vim.inspect listed))))))]

   ["a headless start leaves the session alone"
    (fn []
      (let [dir (h.project [:a.txt])]
        (save-session dir :a.txt)
        (let [nvim (h.start-headless dir)
              _ (h.wait-until #(= 1 (h.exec-lua nvim "return vim.v.vim_did_enter")))
              names (h.buffer-names nvim)]
          (h.stop nvim)
          (h.check (not (h.has-buffer? names :/a.txt))
                   (.. "headless start restored the session: " (vim.inspect names))))))]

   ["<leader>qr resets to the dashboard and forgets the session"
    (fn []
      (let [dir (h.project [:a.txt])]
        (save-session dir :a.txt)
        (let [nvim (h.start dir)]
          (h.wait-until #(h.ends-with? (. (h.current nvim) :name) :/a.txt))
          (h.start-fake-lsp nvim)
          (h.exec-lua nvim "vim.cmd.tabnew() vim.cmd.terminal()")
          (h.press nvim "<Esc><C-\\><C-n> qr")
          (let [dashboard? (h.wait-until #(= (. (h.current nvim) :filetype) :snacks_dashboard) 5000)
                cleared? (h.wait-until #(= 0 (length (h.lsp-client-names nvim))) 5000)
                names (h.buffer-names nvim)
                tabs (h.exec-lua nvim "return #vim.api.nvim_list_tabpages()")
                saved? (h.session-saved? nvim)]
            (h.stop nvim)
            (h.check dashboard? (.. "expected the dashboard, got " (vim.inspect names)))
            (h.check cleared? "an LSP client outlived the reset")
            (h.check (not (h.has-buffer? names :/a.txt)) (.. "a.txt outlived the reset: " (vim.inspect names)))
            (h.check (not (: (vim.iter names) :any #(vim.startswith $1 "term://")))
                     (.. "a terminal outlived the reset: " (vim.inspect names)))
            (h.check (= tabs 1) (.. tabs " tabs outlived the reset"))
            (h.check (not saved?) "the session file outlived the reset"))
          (let [nvim (h.start dir)
                dashboard? (h.wait-until #(= (. (h.current nvim) :filetype) :snacks_dashboard) 5000)]
            (h.stop nvim)
            (h.check dashboard? "the next start restored a session anyway")))))]

   ["<leader>qr refuses while a buffer has unsaved changes"
    (fn []
      (let [dir (h.project [:a.txt])
            nvim (h.start dir [:a.txt])]
        (h.exec-lua nvim "vim.api.nvim_buf_set_lines(0, 0, -1, false, {'edited'})")
        (h.press nvim "<Esc> qr")
        (vim.wait 1000)
        (let [buf (h.current nvim)
              modified? (h.exec-lua nvim "return vim.bo.modified")]
          (h.stop nvim)
          (h.check (and (h.ends-with? buf.name :/a.txt) modified?)
                   (.. "the edit did not survive: " (vim.inspect buf))))))]])
