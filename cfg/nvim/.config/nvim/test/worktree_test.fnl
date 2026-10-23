(local h (dofile (.. (vim.fs.dirname (vim.fs.abspath (. arg 0))) "/harness.lua")))

(fn save-session [dir file]
  (h.stop (h.start dir [file])))

(fn switch [nvim dir]
  (h.exec-lua nvim "require('config.worktree').switch(...)" dir))

(fn cwd [nvim]
  (h.exec-lua nvim "return vim.uv.fs_realpath(vim.fn.getcwd())"))

(fn under? [names dir]
  (: (vim.iter names) :any #(vim.startswith $1 (.. dir "/"))))

(fn statusline-label [nvim name]
  "The statusline's `name` label and its background, or false while it isn't shown."
  (h.exec-lua nvim "
    local name = ...
    local line = vim.api.nvim_eval_statusline(vim.o.statusline, {highlights = true})
    local at = line.str:find(' ' .. name .. ' ', 1, true)
    if not at then return false end
    local group
    for _, hl in ipairs(line.highlights) do
      if hl.start < at then group = hl.group end
    end
    return {bg = vim.api.nvim_get_hl(0, {name = group, link = false}).bg}" name))

(fn dashboard-label [nvim name]
  (h.exec-lua nvim "
    local name = ...
    if vim.bo.filetype ~= 'snacks_dashboard' then return false end
    for row, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
      local col = line:find(name, 1, true)
      if col then
        local marks = vim.api.nvim_buf_get_extmarks(0, -1, {row - 1, col - 1}, {row - 1, col - 1},
                                                    {details = true, overlap = true})
        return marks[1] and marks[1][4].hl_group or ''
      end
    end
    return false" name))

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

   ["switch to a worktree without a session opens nothing"
    (fn []
      (let [(main worktrees) (h.repo-with-worktrees [:a.txt] [:feature])
            nvim (h.start main [:a.txt])]
        (switch nvim worktrees.feature)
        (vim.wait 1000)
        (let [buf (h.current nvim)
              names (h.buffer-names nvim)
              dir (cwd nvim)]
          (h.stop nvim)
          (h.check (vim.deep_equal buf {:name "" :filetype ""})
                   (.. "expected an empty editor, got " (vim.inspect buf)))
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
                                {worktrees.feature "Fix the thing"})
              by-path (collect [_ item (ipairs items)] (values item.path item))]
          (h.stop nvim)
          (h.check (and (= 2 (length items)) (. by-path main) (. by-path worktrees.feature))
                   (.. "expected main and feature, got " (vim.inspect items)))
          (h.check (= (. by-path worktrees.feature :agent) "Fix the thing")
                   (.. "feature lost its agent: " (vim.inspect items))))))]

   ["list puts the most recently touched worktree first"
    (fn []
      (let [(main worktrees) (h.repo-with-worktrees [:a.txt] [:old :new])
            now (os.time)
            touch (fn [git-dir age]
                    (vim.uv.fs_utime (.. git-dir "/index") (- now age) (- now age)))]
        (touch (.. main "/.git") 100)
        (touch (.. main "/.git/worktrees/old") 200)
        (touch (.. main "/.git/worktrees/new") -100)
        (let [nvim (h.start main)
              items (h.exec-lua nvim "return require('config.worktree').list(...)" {})]
          (h.stop nvim)
          (h.check (vim.deep_equal (vim.tbl_map #(. $1 :path) items)
                                   [worktrees.new main worktrees.old])
                   (.. "expected new, main, old; got " (vim.inspect items))))))]

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

   ["<leader>gw switches away from a worktree that has been deleted"
    (fn []
      (let [(main worktrees) (h.repo-with-worktrees [:a.txt] [:feature])
            nvim (h.start worktrees.feature [:a.txt])]
        (h.check (h.wait-until #(statusline-label nvim :feature) 5000) "statusline never named feature")
        (vim.fn.delete worktrees.feature :rf)
        (pick-worktree nvim main)
        (h.press nvim "<Esc> gw")
        (let [switched? (h.wait-until #(= (cwd nvim) main) 5000)
              dir (cwd nvim)]
          (h.stop nvim)
          (h.check switched? (.. "cwd is " (vim.inspect dir))))))]

   ["the terminal title names the worktree, and follows a switch"
    (fn []
      (let [(main worktrees) (h.repo-with-worktrees [:a.txt] [:feature])
            nvim (h.start main [:a.txt])
            title #(h.exec-lua nvim "return vim.o.title and vim.api.nvim_eval_statusline(vim.o.titlestring, {}).str")
            before (title)]
        (switch nvim worktrees.feature)
        (let [after (title)]
          (h.stop nvim)
          (h.check (and (= before :repo) (= after :feature))
                   (.. "titles were " (vim.inspect [before after]))))))]

   ["the statusline names the worktree, loud only in a linked one"
    (fn []
      (let [(main worktrees) (h.repo-with-worktrees [:a.txt] [:feature])
            nvim (h.start main [:a.txt])
            _ (h.wait-until #(statusline-label nvim :repo) 5000)
            in-main (statusline-label nvim :repo)]
        (switch nvim worktrees.feature)
        (h.wait-until #(statusline-label nvim :feature) 5000)
        (let [in-feature (statusline-label nvim :feature)
              warn (h.exec-lua nvim "return vim.api.nvim_get_hl(0, {name = 'DiagnosticWarn', link = false}).fg")]
          (h.stop nvim)
          (h.check in-main "main checkout's name missing")
          (h.check (not= warn in-main.bg) "main checkout's name is loud")
          (h.check in-feature "linked worktree's name missing")
          (h.check (= warn in-feature.bg) "linked worktree's name is quiet"))))]

   ["the dashboard names the worktree, loud only in a linked one"
    (fn []
      (let [(main worktrees) (h.repo-with-worktrees [:a.txt] [:feature])
            in-main (h.start main)
            in-feature (h.start worktrees.feature)]
        (h.wait-until #(and (dashboard-label in-main :repo) (dashboard-label in-feature :feature)) 5000)
        (let [main-hl (dashboard-label in-main :repo)
              feature-hl (dashboard-label in-feature :feature)]
          (h.stop in-main)
          (h.stop in-feature)
          (h.check main-hl "main checkout's name missing")
          (h.check (= main-hl :Comment) (.. "main checkout's name is " (vim.inspect main-hl)))
          (h.check (= feature-hl :DiagnosticWarn) (.. "linked worktree's name is " (vim.inspect feature-hl))))))]

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
