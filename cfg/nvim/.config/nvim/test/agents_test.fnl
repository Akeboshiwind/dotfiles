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

(h.run
  [["<leader>ga switches to the directory of the row picked from agent-rows"
    (fn []
      (let [(main worktrees) (h.repo-with-worktrees [:a.txt] [:feature])]
        (fake-agent-rows [(.. worktrees.feature "\t✻ feature  Working · on it  1m")])
        (let [nvim (h.start main [:a.txt])]
          ;; Polling the child over RPC while fzf runs stalls fzf, so the child reports back instead
          (h.exec-lua nvim "vim.api.nvim_create_autocmd('User', {pattern = 'WorktreeSwitched', callback = function()
                              vim.rpcnotify(1, 'nvim_set_var', 'switched', true) end})")
          (h.press nvim "<Esc> ga")
          (let [switched? (h.wait-until #vim.g.switched 5000)
                dir (cwd nvim)]
            (h.stop nvim)
            (h.check (and switched? (= dir worktrees.feature)) (.. "cwd is " dir))))))]])
