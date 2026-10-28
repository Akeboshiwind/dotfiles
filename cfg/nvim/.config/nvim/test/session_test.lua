-- [nfnl] test/session_test.fnl
local h = dofile((vim.fs.dirname(vim.fs.abspath(arg[0])) .. "/harness.lua"))
local function save_session(dir, file)
  return h.stop(h.start(dir, {file}))
end
local function _1_()
  local dir = h.project({"a.txt"})
  save_session(dir, "a.txt")
  local nvim = h.start(dir)
  local restored_3f
  local function _2_()
    return h["ends-with?"](h.current(nvim).name, "/a.txt")
  end
  restored_3f = h["wait-until"](_2_)
  local buf = h.current(nvim)
  local filetypes = h["buffer-filetypes"](nvim)
  h.stop(nvim)
  h.check(restored_3f, ("expected a.txt, got " .. vim.inspect(buf)))
  h.check((buf.filetype == "text"), ("restored buffer skipped FileType: " .. vim.inspect(buf)))
  return h.check(not vim.tbl_contains(filetypes, "snacks_dashboard"), ("dashboard outlived the restore: " .. vim.inspect(filetypes)))
end
local function _3_()
  local nvim = h.start(h.project({"a.txt"}))
  local dashboard_3f
  local function _4_()
    return (h.current(nvim).filetype == "snacks_dashboard")
  end
  dashboard_3f = h["wait-until"](_4_)
  local buf = h.current(nvim)
  h.stop(nvim)
  return h.check(dashboard_3f, ("expected the dashboard, got " .. vim.inspect(buf)))
end
local function _5_()
  local dir = h.project({"a.txt", "b.txt"})
  save_session(dir, "a.txt")
  local nvim = h.start(dir, {"b.txt"})
  local names = h["buffer-names"](nvim)
  h.stop(nvim)
  return h.check(not h["has-buffer?"](names, "/a.txt"), ("session leaked into an explicit start: " .. vim.inspect(names)))
end
local function _6_()
  local dir = h.project({"a.txt", "b.txt"})
  local nvim = h.start(dir, {"b.txt"})
  h["exec-lua"](nvim, "vim.cmd('edit a.txt | bdelete b.txt')")
  h.stop(nvim)
  local nvim0 = h.start(dir)
  local _
  local function _7_()
    return h["ends-with?"](h.current(nvim0).name, "/a.txt")
  end
  _ = h["wait-until"](_7_)
  local listed = h["exec-lua"](nvim0, "return vim.tbl_map(vim.api.nvim_buf_get_name, vim.tbl_filter(function(b) return vim.bo[b].buflisted end, vim.api.nvim_list_bufs()))")
  h.stop(nvim0)
  return h.check(not h["has-buffer?"](listed, "/b.txt"), ("the closed file came back: " .. vim.inspect(listed)))
end
local function _8_()
  local dir = h.project({"a.txt"})
  save_session(dir, "a.txt")
  local nvim = h["start-headless"](dir)
  local _
  local function _9_()
    return (1 == h["exec-lua"](nvim, "return vim.v.vim_did_enter"))
  end
  _ = h["wait-until"](_9_)
  local names = h["buffer-names"](nvim)
  h.stop(nvim)
  return h.check(not h["has-buffer?"](names, "/a.txt"), ("headless start restored the session: " .. vim.inspect(names)))
end
local function _10_()
  local dir = h.project({"a.txt"})
  save_session(dir, "a.txt")
  local nvim = h.start(dir)
  local function _11_()
    return h["ends-with?"](h.current(nvim).name, "/a.txt")
  end
  h["wait-until"](_11_)
  h["start-fake-lsp"](nvim)
  h["exec-lua"](nvim, "vim.cmd.tabnew() vim.cmd.terminal()")
  h.press(nvim, "<Esc><C-\\><C-n> qr")
  do
    local dashboard_3f
    local function _12_()
      return (h.current(nvim).filetype == "snacks_dashboard")
    end
    dashboard_3f = h["wait-until"](_12_, 5000)
    local cleared_3f
    local function _13_()
      return (0 == #h["lsp-client-names"](nvim))
    end
    cleared_3f = h["wait-until"](_13_, 5000)
    local names = h["buffer-names"](nvim)
    local tabs = h["exec-lua"](nvim, "return #vim.api.nvim_list_tabpages()")
    local saved_3f = h["session-saved?"](nvim)
    h.stop(nvim)
    h.check(dashboard_3f, ("expected the dashboard, got " .. vim.inspect(names)))
    h.check(cleared_3f, "an LSP client outlived the reset")
    h.check(not h["has-buffer?"](names, "/a.txt"), ("a.txt outlived the reset: " .. vim.inspect(names)))
    local function _14_(_241)
      return vim.startswith(_241, "term://")
    end
    h.check(not vim.iter(names):any(_14_), ("a terminal outlived the reset: " .. vim.inspect(names)))
    h.check((tabs == 1), (tabs .. " tabs outlived the reset"))
    h.check(not saved_3f, "the session file outlived the reset")
  end
  local nvim0 = h.start(dir)
  local dashboard_3f
  local function _15_()
    return (h.current(nvim0).filetype == "snacks_dashboard")
  end
  dashboard_3f = h["wait-until"](_15_, 5000)
  h.stop(nvim0)
  return h.check(dashboard_3f, "the next start restored a session anyway")
end
local function _16_()
  local dir = h.project({"a.txt"})
  local nvim = h.start(dir, {"a.txt"})
  h["exec-lua"](nvim, "vim.api.nvim_buf_set_lines(0, 0, -1, false, {'edited'})")
  h.press(nvim, "<Esc> qr")
  vim.wait(1000)
  local buf = h.current(nvim)
  local modified_3f = h["exec-lua"](nvim, "return vim.bo.modified")
  h.stop(nvim)
  return h.check((h["ends-with?"](buf.name, "/a.txt") and modified_3f), ("the edit did not survive: " .. vim.inspect(buf)))
end
return h.run({{"a bare start restores the cwd's session", _1_}, {"a bare start without a session shows the dashboard", _3_}, {"a start with a file argument opens only that file", _5_}, {"a file closed after starting with it as an argument stays closed in the session", _6_}, {"a headless start leaves the session alone", _8_}, {"<leader>qr resets to the dashboard and forgets the session", _10_}, {"<leader>qr refuses while a buffer has unsaved changes", _16_}})
