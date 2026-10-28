(local h (dofile (.. (vim.fs.dirname (vim.fs.abspath (. arg 0))) "/harness.lua")))

(fn cwd [nvim]
  (h.exec-lua nvim "return vim.uv.fs_realpath(vim.fn.getcwd())"))

(fn fake-agent-rows [rows]
  (let [bin (vim.fn.tempname)
        script (.. bin "/agent-rows")]
    (vim.fn.mkdir bin :p)
    (vim.fn.writefile (vim.list_extend ["#!/bin/sh" "cat <<'EOF'"] (vim.list_extend rows ["EOF"]))
                      script)
    (vim.uv.fs_chmod script 493)
    (set vim.env.PATH (.. bin ":" vim.env.PATH))))

(fn report-switches [nvim]
  "Polling the child over RPC while fzf runs stalls fzf, so the child reports back instead."
  (set vim.g.switched nil)
  (h.exec-lua nvim "vim.api.nvim_create_autocmd('User', {pattern = 'WorktreeSwitched', callback = function()
                      vim.rpcnotify(1, 'nvim_set_var', 'switched', true) end})"))

(h.run
  [["<leader>ga switches to the directory of the row picked from agent-rows"
    (fn []
      (let [(main worktrees) (h.repo-with-worktrees [:a.txt] [:feature])]
        (fake-agent-rows [(.. worktrees.feature "\t✻ feature  Working · on it  1m")])
        (let [nvim (h.start main [:a.txt])]
          (report-switches nvim)
          (h.press nvim "<Esc> ga")
          (let [switched? (h.wait-until #vim.g.switched 5000)
                dir (cwd nvim)]
            (h.stop nvim)
            (h.check (and switched? (= dir worktrees.feature)) (.. "cwd is " dir))))))]

   ["<leader>ga stays put when the picked row is a heading with no directory"
    (fn []
      (let [(main) (h.repo-with-worktrees [:a.txt] [])]
        (fake-agent-rows ["\tPinned"])
        (let [nvim (h.start main [:a.txt])]
          (report-switches nvim)
          (h.press nvim "<Esc> ga")
          (let [switched? (h.wait-until #vim.g.switched 3000)
                dir (cwd nvim)
                err (h.exec-lua nvim "return vim.v.errmsg")]
            (h.stop nvim)
            (h.check (and (not switched?) (= dir main)) (.. "switched to " dir))
            (h.check (= "" err) (.. "failed with " err))))))]])
