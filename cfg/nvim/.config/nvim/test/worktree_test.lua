-- [nfnl] test/worktree_test.fnl
local h = dofile((vim.fs.dirname(vim.fs.abspath(arg[0])) .. "/harness.lua"))
local function save_session(dir, file)
  return h.stop(h.start(dir, {file}))
end
local function switch(nvim, dir)
  return h["exec-lua"](nvim, "require('config.worktree').switch(...)", dir)
end
local function cwd(nvim)
  return h["exec-lua"](nvim, "return vim.uv.fs_realpath(vim.fn.getcwd())")
end
local function under_3f(names, dir)
  local function _1_(_241)
    return vim.startswith(_241, (dir .. "/"))
  end
  return vim.iter(names):any(_1_)
end
local function statusline_label(nvim, name)
  return h["exec-lua"](nvim, "\n    local name = ...\n    local line = vim.api.nvim_eval_statusline(vim.o.statusline, {highlights = true})\n    local at = line.str:find(' ' .. name .. ' ', 1, true)\n    if not at then return false end\n    local group\n    for _, hl in ipairs(line.highlights) do\n      if hl.start < at then group = hl.group end\n    end\n    return {bg = vim.api.nvim_get_hl(0, {name = group, link = false}).bg}", name)
end
local function dashboard_label(nvim, name)
  return h["exec-lua"](nvim, "\n    local name = ...\n    if vim.bo.filetype ~= 'snacks_dashboard' then return false end\n    for row, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do\n      local col = line:find(name, 1, true)\n      if col then\n        local marks = vim.api.nvim_buf_get_extmarks(0, -1, {row - 1, col - 1}, {row - 1, col - 1},\n                                                    {details = true, overlap = true})\n        return marks[1] and marks[1][4].hl_group or ''\n      end\n    end\n    return false", name)
end
local function pick_worktree(nvim, dir)
  return h["exec-lua"](nvim, "\n    local dir = ...\n    vim.ui.select = function(items, _, choose)\n      for _, item in ipairs(items) do\n        if item.path == dir then return choose(item) end\n      end\n      choose(nil)\n    end", dir)
end
local function _2_()
  local main, worktrees = h["repo-with-worktrees"]({"a.txt"}, {"feature"})
  local feature = worktrees.feature
  vim.fn.writefile({"c"}, (feature .. "/c.txt"))
  save_session(feature, "c.txt")
  do
    local nvim = h.start(main, {"a.txt"})
    switch(nvim, feature)
    local restored_3f
    local function _3_()
      return (h.current(nvim).name == (feature .. "/c.txt"))
    end
    restored_3f = h["wait-until"](_3_, 5000)
    local buf = h.current(nvim)
    local names = h["buffer-names"](nvim)
    local dir = cwd(nvim)
    h.stop(nvim)
    h.check(restored_3f, ("expected feature's c.txt, got " .. vim.inspect(buf)))
    h.check((dir == feature), ("cwd is " .. dir))
    h.check(not under_3f(names, main), ("main's buffers survived: " .. vim.inspect(names)))
  end
  local nvim = h.start(main)
  local restored_3f
  local function _4_()
    return (h.current(nvim).name == (main .. "/a.txt"))
  end
  restored_3f = h["wait-until"](_4_, 5000)
  h.stop(nvim)
  return h.check(restored_3f, "main's session wasn't saved on the way out")
end
local function _5_()
  local main, worktrees = h["repo-with-worktrees"]({"a.txt"}, {"feature"})
  local nvim = h.start(main, {"a.txt"})
  switch(nvim, worktrees.feature)
  vim.wait(1000)
  local buf = h.current(nvim)
  local names = h["buffer-names"](nvim)
  local dir = cwd(nvim)
  h.stop(nvim)
  h.check(vim.deep_equal(buf, {name = "", filetype = ""}), ("expected an empty editor, got " .. vim.inspect(buf)))
  h.check((dir == worktrees.feature), ("cwd is " .. dir))
  return h.check(not under_3f(names, main), ("main's buffers survived: " .. vim.inspect(names)))
end
local function _6_()
  local main, worktrees = h["repo-with-worktrees"]({"a.txt"}, {"feature"})
  local nvim = h.start(main, {"a.txt"})
  h["exec-lua"](nvim, "vim.api.nvim_buf_set_lines(0, 0, -1, false, {'edited'})")
  switch(nvim, worktrees.feature)
  local dir = cwd(nvim)
  local modified_3f = h["exec-lua"](nvim, "return vim.bo.modified")
  h.stop(nvim)
  h.check((dir == main), ("switched anyway, cwd is " .. dir))
  return h.check(modified_3f, "the edit did not survive")
end
local function _7_()
  local main, worktrees = h["repo-with-worktrees"]({"a.txt"}, {"feature"})
  local nvim = h.start(main, {"a.txt"})
  h["start-fake-lsp"](nvim)
  h["exec-lua"](nvim, "vim.api.nvim_create_autocmd('User', {pattern = 'WorktreeSwitched',\n                            callback = function(ev) vim.g.switched = ev.data end})")
  switch(nvim, worktrees.feature)
  local stopped_3f
  local function _8_()
    return (0 == #h["lsp-client-names"](nvim))
  end
  stopped_3f = h["wait-until"](_8_, 5000)
  local switched = h["exec-lua"](nvim, "return vim.g.switched")
  h.stop(nvim)
  h.check(stopped_3f, "an LSP client outlived the switch")
  return h.check((switched and (switched.from == main) and (switched.to == worktrees.feature)), ("WorktreeSwitched carried " .. vim.inspect(switched)))
end
local function _9_()
  local main, worktrees = h["repo-with-worktrees"]({"a.txt"}, {"feature", "gone"})
  local nvim = h.start(main)
  vim.fn.delete(worktrees.gone, "rf")
  local items = h["exec-lua"](nvim, "return require('config.worktree').list(...)", {[worktrees.feature] = "Fix the thing"})
  h.stop(nvim)
  local function _10_(_241)
    return _241.path
  end
  h.check(vim.deep_equal(vim.tbl_map(_10_, items), {main, worktrees.feature}), ("expected main and feature, got " .. vim.inspect(items)))
  return h.check((items[2].agent == "Fix the thing"), ("feature lost its agent: " .. vim.inspect(items)))
end
local function _11_()
  local main, worktrees = h["repo-with-worktrees"]({"a.txt"}, {"feature"})
  local nvim = h.start(main, {"a.txt"})
  pick_worktree(nvim, worktrees.feature)
  h.press(nvim, "<Esc> gw")
  local switched_3f
  local function _12_()
    return (cwd(nvim) == worktrees.feature)
  end
  switched_3f = h["wait-until"](_12_, 5000)
  local dir = cwd(nvim)
  h.stop(nvim)
  return h.check(switched_3f, ("cwd is " .. dir))
end
local function _13_()
  local main, worktrees = h["repo-with-worktrees"]({"a.txt"}, {"feature"})
  local nvim = h.start(worktrees.feature, {"a.txt"})
  local function _14_()
    return statusline_label(nvim, "feature")
  end
  h.check(h["wait-until"](_14_, 5000), "statusline never named feature")
  vim.fn.delete(worktrees.feature, "rf")
  pick_worktree(nvim, main)
  h.press(nvim, "<Esc> gw")
  local switched_3f
  local function _15_()
    return (cwd(nvim) == main)
  end
  switched_3f = h["wait-until"](_15_, 5000)
  local dir = cwd(nvim)
  h.stop(nvim)
  return h.check(switched_3f, ("cwd is " .. vim.inspect(dir)))
end
local function _16_()
  local main, worktrees = h["repo-with-worktrees"]({"a.txt"}, {"feature"})
  local nvim = h.start(main, {"a.txt"})
  local title
  local function _17_()
    return h["exec-lua"](nvim, "return vim.o.title and vim.api.nvim_eval_statusline(vim.o.titlestring, {}).str")
  end
  title = _17_
  local before = title()
  switch(nvim, worktrees.feature)
  local after = title()
  h.stop(nvim)
  return h.check(((before == "repo") and (after == "feature")), ("titles were " .. vim.inspect({before, after})))
end
local function _18_()
  local main, worktrees = h["repo-with-worktrees"]({"a.txt"}, {"feature"})
  local nvim = h.start(main, {"a.txt"})
  local _
  local function _19_()
    return statusline_label(nvim, "repo")
  end
  _ = h["wait-until"](_19_, 5000)
  local in_main = statusline_label(nvim, "repo")
  switch(nvim, worktrees.feature)
  local function _20_()
    return statusline_label(nvim, "feature")
  end
  h["wait-until"](_20_, 5000)
  local in_feature = statusline_label(nvim, "feature")
  local warn = h["exec-lua"](nvim, "return vim.api.nvim_get_hl(0, {name = 'DiagnosticWarn', link = false}).fg")
  h.stop(nvim)
  h.check(in_main, "main checkout's name missing")
  h.check((warn ~= in_main.bg), "main checkout's name is loud")
  h.check(in_feature, "linked worktree's name missing")
  return h.check((warn == in_feature.bg), "linked worktree's name is quiet")
end
local function _21_()
  local main, worktrees = h["repo-with-worktrees"]({"a.txt"}, {"feature"})
  local in_main = h.start(main)
  local in_feature = h.start(worktrees.feature)
  local function _22_()
    return (dashboard_label(in_main, "repo") and dashboard_label(in_feature, "feature"))
  end
  h["wait-until"](_22_, 5000)
  local main_hl = dashboard_label(in_main, "repo")
  local feature_hl = dashboard_label(in_feature, "feature")
  h.stop(in_main)
  h.stop(in_feature)
  h.check(main_hl, "main checkout's name missing")
  h.check((main_hl == "Comment"), ("main checkout's name is " .. vim.inspect(main_hl)))
  return h.check((feature_hl == "DiagnosticWarn"), ("linked worktree's name is " .. vim.inspect(feature_hl)))
end
local function _23_()
  local main, worktrees = h["repo-with-worktrees"]({"a.txt"}, {"feature"})
  local nvim = h.start(main, {"a.txt"})
  pick_worktree(nvim, worktrees.feature)
  h["exec-lua"](nvim, "LazyVim.pick.open = function(command, opts) vim.g.picked = {command, opts.cwd} end")
  h.press(nvim, "<Esc> fw")
  local picked_3f
  local function _24_()
    return h["exec-lua"](nvim, "return vim.g.picked ~= nil")
  end
  picked_3f = h["wait-until"](_24_, 5000)
  local picked = h["exec-lua"](nvim, "return vim.g.picked")
  local dir = cwd(nvim)
  h.stop(nvim)
  h.check((picked_3f and vim.deep_equal(picked, {"files", worktrees.feature})), ("picker opened with " .. vim.inspect(picked)))
  return h.check((dir == main), ("switched anyway, cwd is " .. dir))
end
return h.run({{"switch saves this worktree's session and restores the target's", _2_}, {"switch to a worktree without a session opens nothing", _5_}, {"switch refuses while a buffer has unsaved changes", _6_}, {"switch stops LSP clients and announces WorktreeSwitched", _7_}, {"list shows each live worktree, with its agent's name", _9_}, {"<leader>gw switches to the picked worktree", _11_}, {"<leader>gw switches away from a worktree that has been deleted", _13_}, {"the terminal title names the worktree, and follows a switch", _16_}, {"the statusline names the worktree, loud only in a linked one", _18_}, {"the dashboard names the worktree, loud only in a linked one", _21_}, {"<leader>fw finds files in the picked worktree without switching", _23_}})
