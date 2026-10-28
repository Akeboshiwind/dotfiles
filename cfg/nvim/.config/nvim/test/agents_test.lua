-- [nfnl] test/agents_test.fnl
local h = dofile((vim.fs.dirname(vim.fs.abspath(arg[0])) .. "/harness.lua"))
local function cwd(nvim)
  return h["exec-lua"](nvim, "return vim.uv.fs_realpath(vim.fn.getcwd())")
end
local function fake_agent_rows(rows)
  local bin = vim.fn.tempname()
  local script = (bin .. "/agent-rows")
  vim.fn.mkdir(bin, "p")
  vim.fn.writefile(vim.list_extend({"#!/bin/sh", "cat <<'EOF'"}, vim.list_extend(rows, {"EOF"})), script)
  vim.uv.fs_chmod(script, 493)
  vim.env.PATH = (bin .. ":" .. vim.env.PATH)
  return nil
end
local function report_switches(nvim)
  vim.g.switched = nil
  return h["exec-lua"](nvim, "vim.api.nvim_create_autocmd('User', {pattern = 'WorktreeSwitched', callback = function()\n                      vim.rpcnotify(1, 'nvim_set_var', 'switched', true) end})")
end
local function _1_()
  local main, worktrees = h["repo-with-worktrees"]({"a.txt"}, {"feature"})
  fake_agent_rows({(worktrees.feature .. "\t\226\156\187 feature  Working \194\183 on it  1m")})
  local nvim = h.start(main, {"a.txt"})
  report_switches(nvim)
  h.press(nvim, "<Esc> ga")
  local switched_3f
  local function _2_()
    return vim.g.switched
  end
  switched_3f = h["wait-until"](_2_, 5000)
  local dir = cwd(nvim)
  h.stop(nvim)
  return h.check((switched_3f and (dir == worktrees.feature)), ("cwd is " .. dir))
end
local function _3_()
  local main = h["repo-with-worktrees"]({"a.txt"}, {})
  fake_agent_rows({"\tPinned"})
  local nvim = h.start(main, {"a.txt"})
  report_switches(nvim)
  h.press(nvim, "<Esc> ga")
  local switched_3f
  local function _4_()
    return vim.g.switched
  end
  switched_3f = h["wait-until"](_4_, 3000)
  local dir = cwd(nvim)
  local err = h["exec-lua"](nvim, "return vim.v.errmsg")
  h.stop(nvim)
  h.check((not switched_3f and (dir == main)), ("switched to " .. dir))
  return h.check(("" == err), ("failed with " .. err))
end
return h.run({{"<leader>ga switches to the directory of the row picked from agent-rows", _1_}, {"<leader>ga stays put when the picked row is a heading with no directory", _3_}})
