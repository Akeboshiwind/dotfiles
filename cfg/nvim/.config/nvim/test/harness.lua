-- [nfnl] test/harness.fnl
local config_dir = vim.fs.dirname(vim.fs.dirname(vim.fs.abspath(arg[0])))
local function tempdir()
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, "p")
  return dir
end
local root = tempdir()
local xdg_config = (root .. "/config")
vim.fn.mkdir(xdg_config, "p")
vim.uv.fs_symlink(config_dir, (xdg_config .. "/nvim"))
local env = {XDG_CONFIG_HOME = xdg_config, XDG_STATE_HOME = (root .. "/state")}
local children = {}
local function spawn(args, cwd)
  local chan = vim.fn.jobstart(args, {rpc = true, cwd = cwd, env = env})
  table.insert(children, chan)
  return chan
end
local function wait_until(pred, _3fms)
  return vim.wait((_3fms or 15000), pred, 50)
end
local function exec_lua(chan, code, ...)
  return vim.rpcrequest(chan, "nvim_exec_lua", code, {...})
end
local function start(cwd, _3fargs)
  local chan = spawn(vim.list_extend({"nvim", "--embed"}, (_3fargs or {})), cwd)
  vim.rpcrequest(chan, "nvim_ui_attach", 80, 24, {})
  local function _1_()
    return (1 == exec_lua(chan, "return vim.v.vim_did_enter"))
  end
  wait_until(_1_)
  return chan
end
local function start_headless(cwd)
  return spawn({"nvim", "--headless", "--embed"}, cwd)
end
local function stop(chan)
  local left = ("harness_left_" .. chan)
  exec_lua(chan, "local name = ...\n                    vim.api.nvim_create_autocmd('VimLeave', {callback = function()\n                      vim.rpcnotify(1, 'nvim_set_var', name, true) end})", left)
  vim.rpcnotify(chan, "nvim_command", "qa!")
  local function _2_()
    return (vim.g[left] or (0 == vim.fn.jobwait({chan}, 0)[1]))
  end
  if not wait_until(_2_, 10000) then
    error("child never reached VimLeave", 0)
  else
  end
  vim.fn.jobstop(chan)
  return vim.fn.jobwait({chan}, 5000)
end
local function buffer_names(chan)
  return exec_lua(chan, "return vim.tbl_map(vim.api.nvim_buf_get_name, vim.api.nvim_list_bufs())")
end
local function buffer_filetypes(chan)
  return exec_lua(chan, "return vim.tbl_map(function(b) return vim.bo[b].filetype end, vim.api.nvim_list_bufs())")
end
local function current(chan)
  return exec_lua(chan, "return {name = vim.api.nvim_buf_get_name(0), filetype = vim.bo.filetype}")
end
local function press(chan, keys)
  return vim.rpcrequest(chan, "nvim_input", keys)
end
local function start_fake_lsp(chan)
  return exec_lua(chan, "\n    vim.lsp.start({name = 'fake', cmd = function(dispatchers)\n      local closing = false\n      local function exit()\n        if not closing then closing = true dispatchers.on_exit(0, 0) end\n      end\n      return {\n        request = function(method, _, callback)\n          callback(nil, method == 'initialize' and {capabilities = {}} or nil)\n          return true, 1\n        end,\n        notify = function(method) if method == 'exit' then exit() end return true end,\n        is_closing = function() return closing end,\n        terminate = exit,\n      }\n    end})")
end
local function lsp_client_names(chan)
  return exec_lua(chan, "return vim.tbl_map(function(c) return c.name end, vim.lsp.get_clients())")
end
local function session_saved_3f(chan)
  return (1 == exec_lua(chan, "return vim.fn.filereadable(require('persistence').current())"))
end
local function project(files)
  local dir = tempdir()
  for _, file in ipairs(files) do
    vim.fn.writefile({file}, (dir .. "/" .. file))
  end
  return dir
end
local function git(dir, ...)
  local result = vim.system({"git", "-C", dir, "-c", "user.name=test", "-c", "user.email=test@example.com", "-c", "commit.gpgsign=false", ...}, {text = true, env = {GIT_CONFIG_GLOBAL = "/dev/null"}}):wait()
  if (0 ~= result.code) then
    error(result.stderr)
  else
  end
  return vim.trim(result.stdout)
end
local function repo_with_worktrees(files, names)
  local main = (tempdir() .. "/repo")
  local worktrees = {}
  vim.fn.mkdir(main)
  for _, file in ipairs(files) do
    vim.fn.writefile({file}, (main .. "/" .. file))
  end
  git(main, "init", "-q", "-b", "main")
  git(main, "add", ".")
  git(main, "commit", "-q", "-m", "init")
  for _, name in ipairs(names) do
    local path = (vim.fs.dirname(main) .. "/" .. name)
    git(main, "worktree", "add", "-q", "-b", name, path)
    worktrees[name] = vim.uv.fs_realpath(path)
  end
  return vim.uv.fs_realpath(main), worktrees
end
local function ends_with_3f(s, suffix)
  return vim.endswith((s or ""), suffix)
end
local function has_buffer_3f(names, suffix)
  local function _5_(_241)
    return ends_with_3f(_241, suffix)
  end
  return vim.iter(names):any(_5_)
end
local function check(ok_3f, message)
  if not ok_3f then
    return error(message, 0)
  else
    return nil
  end
end
local function run(tests)
  local failed = 0
  for _, _7_ in ipairs(tests) do
    local name = _7_[1]
    local f = _7_[2]
    local t0 = vim.uv.hrtime()
    local ok_3f, err = pcall(f)
    local ms = math.floor(((vim.uv.hrtime() - t0) / 1000000))
    if ok_3f then
      print(("PASS  " .. name .. "  (" .. ms .. "ms)"))
    else
      failed = (failed + 1)
      print(("FAIL  " .. name .. "\n      " .. tostring(err)))
    end
  end
  for _, chan in ipairs(children) do
    vim.fn.jobstop(chan)
  end
  vim.fn.delete(root, "rf")
  local function _9_()
    if (failed == 0) then
      return 0
    else
      return 1
    end
  end
  return os.exit(_9_())
end
return {["wait-until"] = wait_until, ["exec-lua"] = exec_lua, start = start, ["start-headless"] = start_headless, stop = stop, ["buffer-names"] = buffer_names, ["buffer-filetypes"] = buffer_filetypes, current = current, press = press, ["start-fake-lsp"] = start_fake_lsp, ["lsp-client-names"] = lsp_client_names, ["session-saved?"] = session_saved_3f, project = project, git = git, ["repo-with-worktrees"] = repo_with_worktrees, ["ends-with?"] = ends_with_3f, ["has-buffer?"] = has_buffer_3f, check = check, run = run}
