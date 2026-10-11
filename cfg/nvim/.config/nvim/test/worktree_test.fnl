(local h (dofile (.. (vim.fs.dirname (vim.fs.abspath (. arg 0))) "/harness.lua")))

(fn save-session [dir file]
  (h.stop (h.start dir [file])))

(fn switch [nvim dir]
  (h.exec-lua nvim "require('config.worktree').switch(...)" dir))

(fn cwd [nvim]
  (h.exec-lua nvim "return vim.uv.fs_realpath(vim.fn.getcwd())"))

(fn under? [names dir]
  (: (vim.iter names) :any #(vim.startswith $1 (.. dir "/"))))

(fn pick-worktree [nvim dir]
  (h.exec-lua nvim "
    local dir = ...
    vim.ui.select = function(items, _, choose)
      for _, item in ipairs(items) do
        if item.path == dir then return choose(item) end
      end
      choose(nil)
    end" dir))

(h.run
  [["switch saves this worktree's session and restores the target's"
    (fn []
      (let [(main worktrees) (h.repo-with-worktrees [:a.txt] [:feature])
            feature worktrees.feature]
        (vim.fn.writefile [:c] (.. feature "/c.txt"))
        (save-session feature :c.txt)
        (let [nvim (h.start main [:a.txt])]
          (switch nvim feature)
          (let [restored? (h.wait-until #(= (. (h.current nvim) :name) (.. feature "/c.txt")) 5000)
                buf (h.current nvim)
                names (h.buffer-names nvim)
                dir (cwd nvim)]
            (h.stop nvim)
            (h.check restored? (.. "expected feature's c.txt, got " (vim.inspect buf)))
            (h.check (= dir feature) (.. "cwd is " dir))
            (h.check (not (under? names main)) (.. "main's buffers survived: " (vim.inspect names)))))
        (let [nvim (h.start main)
              restored? (h.wait-until #(= (. (h.current nvim) :name) (.. main "/a.txt")) 5000)]
          (h.stop nvim)
          (h.check restored? "main's session wasn't saved on the way out"))))]

   ["switch to a worktree without a session opens its git status"
    (fn []
      (let [(main worktrees) (h.repo-with-worktrees [:a.txt] [:feature])
            nvim (h.start main [:a.txt])]
        (switch nvim worktrees.feature)
        (let [picker? (h.wait-until #(= (. (h.current nvim) :filetype) :TelescopePrompt) 5000)
              buf (h.current nvim)
              names (h.buffer-names nvim)
              dir (cwd nvim)]
          (h.stop nvim)
          (h.check picker? (.. "expected the git status picker, got " (vim.inspect buf)))
          (h.check (= dir worktrees.feature) (.. "cwd is " dir))
          (h.check (not (under? names main)) (.. "main's buffers survived: " (vim.inspect names))))))]

   ["switch refuses while a buffer has unsaved changes"
    (fn []
      (let [(main worktrees) (h.repo-with-worktrees [:a.txt] [:feature])
            nvim (h.start main [:a.txt])]
        (h.exec-lua nvim "vim.api.nvim_buf_set_lines(0, 0, -1, false, {'edited'})")
        (switch nvim worktrees.feature)
        (let [dir (cwd nvim)
              modified? (h.exec-lua nvim "return vim.bo.modified")]
          (h.stop nvim)
          (h.check (= dir main) (.. "switched anyway, cwd is " dir))
          (h.check modified? "the edit did not survive"))))]

   ["switch stops LSP clients and announces WorktreeSwitched"
    (fn []
      (let [(main worktrees) (h.repo-with-worktrees [:a.txt] [:feature])
            nvim (h.start main [:a.txt])]
        (h.start-fake-lsp nvim)
        (h.exec-lua nvim "vim.api.nvim_create_autocmd('User', {pattern = 'WorktreeSwitched',
                            callback = function(ev) vim.g.switched = ev.data end})")
        (switch nvim worktrees.feature)
        (let [stopped? (h.wait-until #(= 0 (length (h.lsp-client-names nvim))) 5000)
              switched (h.exec-lua nvim "return vim.g.switched")]
          (h.stop nvim)
          (h.check stopped? "an LSP client outlived the switch")
          (h.check (and switched (= switched.from main) (= switched.to worktrees.feature))
                   (.. "WorktreeSwitched carried " (vim.inspect switched))))))]

   ["list shows each live worktree, with its agent's name"
    (fn []
      (let [(main worktrees) (h.repo-with-worktrees [:a.txt] [:feature :gone])
            nvim (h.start main)]
        (vim.fn.delete worktrees.gone :rf)
        (let [items (h.exec-lua nvim "return require('config.worktree').list(...)"
                                {worktrees.feature "Fix the thing"})]
          (h.stop nvim)
          (h.check (vim.deep_equal (vim.tbl_map #(. $1 :path) items) [main worktrees.feature])
                   (.. "expected main and feature, got " (vim.inspect items)))
          (h.check (= (. items 2 :agent) "Fix the thing")
                   (.. "feature lost its agent: " (vim.inspect items))))))]

   ["<leader>gw switches to the picked worktree"
    (fn []
      (let [(main worktrees) (h.repo-with-worktrees [:a.txt] [:feature])
            nvim (h.start main [:a.txt])]
        (pick-worktree nvim worktrees.feature)
        (h.press nvim "<Esc> gw")
        (let [switched? (h.wait-until #(= (cwd nvim) worktrees.feature) 5000)
              dir (cwd nvim)]
          (h.stop nvim)
          (h.check switched? (.. "cwd is " dir)))))]

   ["<leader>fw finds files in the picked worktree without switching"
    (fn []
      (let [(main worktrees) (h.repo-with-worktrees [:a.txt] [:feature])
            nvim (h.start main [:a.txt])]
        (pick-worktree nvim worktrees.feature)
        (h.exec-lua nvim "LazyVim.pick.open = function(command, opts) vim.g.picked = {command, opts.cwd} end")
        (h.press nvim "<Esc> fw")
        (let [picked? (h.wait-until #(h.exec-lua nvim "return vim.g.picked ~= nil") 5000)
              picked (h.exec-lua nvim "return vim.g.picked")
              dir (cwd nvim)]
          (h.stop nvim)
          (h.check (and picked? (vim.deep_equal picked [:files worktrees.feature]))
                   (.. "picker opened with " (vim.inspect picked)))
          (h.check (= dir main) (.. "switched anyway, cwd is " dir)))))]])
