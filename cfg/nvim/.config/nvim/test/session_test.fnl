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

   ["a headless start leaves the session alone"
    (fn []
      (let [dir (h.project [:a.txt])]
        (save-session dir :a.txt)
        (let [nvim (h.start-headless dir)
              _ (h.wait-until #(= 1 (h.exec-lua nvim "return vim.v.vim_did_enter")))
              names (h.buffer-names nvim)]
          (h.stop nvim)
          (h.check (not (h.has-buffer? names :/a.txt))
                   (.. "headless start restored the session: " (vim.inspect names))))))]])
