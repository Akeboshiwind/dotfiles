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
  local dir = h.project({"a.txt"})
  save_session(dir, "a.txt")
  local nvim = h["start-headless"](dir)
  local _
  local function _7_()
    return (1 == h["exec-lua"](nvim, "return vim.v.vim_did_enter"))
  end
  _ = h["wait-until"](_7_)
  local names = h["buffer-names"](nvim)
  h.stop(nvim)
  return h.check(not h["has-buffer?"](names, "/a.txt"), ("headless start restored the session: " .. vim.inspect(names)))
end
return h.run({{"a bare start restores the cwd's session", _1_}, {"a bare start without a session shows the dashboard", _3_}, {"a start with a file argument opens only that file", _5_}, {"a headless start leaves the session alone", _6_}})
