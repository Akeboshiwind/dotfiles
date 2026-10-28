-- [nfnl] lua/config/worktree.fnl
local agents = require("config.agents")
local session = require("config.session")
local function realpath(path)
  return (vim.uv.fs_realpath(path) or path)
end
local function live_agents()
  local tbl_21_ = {}
  for _, agent in ipairs(agents.list()) do
    local k_22_, v_23_ = agent.cwd, agent.name
    if ((k_22_ ~= nil) and (v_23_ ~= nil)) then
      tbl_21_[k_22_] = v_23_
    else
    end
  end
  return tbl_21_
end
local function read_info(dir)
  local ran_3f, result
  local function _2_()
    return vim.system({"git", "rev-parse", "--path-format=absolute", "--show-toplevel", "--git-dir", "--git-common-dir"}, {text = true, cwd = dir}):wait()
  end
  ran_3f, result = pcall(_2_)
  if (ran_3f and (0 == result.code)) then
    local _let_3_ = vim.split(result.stdout, "\n", {trimempty = true})
    local top = _let_3_[1]
    local git_dir = _let_3_[2]
    local common_dir = _let_3_[3]
    return {name = vim.fs.basename(top), ["linked?"] = (git_dir ~= common_dir), repo = common_dir}
  else
    return false
  end
end
local infos = {}
local last_cwd = ""
local function info()
  local cwd
  do
    local case_5_ = vim.fn.getcwd()
    if (case_5_ == "") then
      cwd = last_cwd
    elseif (nil ~= case_5_) then
      local dir = case_5_
      last_cwd = dir
      cwd = dir
    else
      cwd = nil
    end
  end
  if (nil == infos[cwd]) then
    infos[cwd] = read_info(cwd)
  else
  end
  return (infos[cwd] or nil)
end
local function parse_worktree(block)
  local item = {}
  for _, line in ipairs(vim.split(block, "\n")) do
    local key, value = line:match("^(%S+)%s?(.*)$")
    if (key == "worktree") then
      item.path = realpath(value)
    elseif (key == "branch") then
      item.branch = (value:gsub("^refs/heads/", ""))
    elseif (key == "detached") then
      item.branch = "(detached)"
    elseif (key == "prunable") then
      item.prunable = true
    else
    end
  end
  return item
end
local function git_dir(path)
  local dot_git = (path .. "/.git")
  local _10_
  do
    local t_9_ = vim.uv.fs_stat(dot_git)
    if (nil ~= t_9_) then
      t_9_ = t_9_.type
    else
    end
    _10_ = t_9_
  end
  if ("directory" == _10_) then
    return dot_git
  else
    local case_12_ = io.open(dot_git)
    if (nil ~= case_12_) then
      local file = case_12_
      local line = file:read("*l")
      file:close()
      return line:match("^gitdir: (.+)$")
    else
      return nil
    end
  end
end
local function touched(path)
  local _16_
  do
    local t_15_ = vim.uv.fs_stat(((git_dir(path) or path) .. "/index"))
    if (nil ~= t_15_) then
      t_15_ = t_15_.mtime
    else
    end
    if (nil ~= t_15_) then
      t_15_ = t_15_.sec
    else
    end
    _16_ = t_15_
  end
  return (_16_ or 0)
end
local function list(_3fagents)
  local agents0 = (_3fagents or live_agents())
  local cwd = realpath(vim.fn.getcwd())
  local repo
  do
    local t_19_ = info()
    if (nil ~= t_19_) then
      t_19_ = t_19_.repo
    else
    end
    repo = t_19_
  end
  local result
  if repo then
    result = vim.system({"git", "worktree", "list", "--porcelain"}, {text = true, cwd = repo}):wait()
  else
    result = nil
  end
  if ((nil == result) or (0 ~= result.code)) then
    return {}
  else
    local tmp_9_
    do
      local tbl_26_ = {}
      local i_27_ = 0
      for _, block in ipairs(vim.split(result.stdout, "\n\n", {trimempty = true})) do
        local val_28_
        do
          local item = parse_worktree(block)
          if not item.prunable then
            item["name"] = vim.fs.basename(item.path)
            item["agent"] = agents0[item.path]
            item["current?"] = (item.path == cwd)
            item["touched"] = touched(item.path)
            val_28_ = item
          else
            val_28_ = nil
          end
        end
        if (nil ~= val_28_) then
          i_27_ = (i_27_ + 1)
          tbl_26_[i_27_] = val_28_
        else
        end
      end
      tmp_9_ = tbl_26_
    end
    local function _24_(_241, _242)
      return (_241.touched > _242.touched)
    end
    table.sort(tmp_9_, _24_)
    return tmp_9_
  end
end
local function format_item(item)
  local _26_
  if item["current?"] then
    _26_ = "* "
  else
    _26_ = "  "
  end
  local _28_
  if item.branch then
    _28_ = ("  [" .. item.branch .. "]")
  else
    _28_ = ""
  end
  local _30_
  if item.agent then
    _30_ = ("  " .. item.agent)
  else
    _30_ = ""
  end
  return (_26_ .. item.name .. _28_ .. _30_)
end
local function pick(prompt, on_choice)
  local function _32_(_241)
    if _241 then
      return on_choice(_241.path)
    else
      return nil
    end
  end
  return vim.ui.select(list(), {prompt = prompt, format_item = format_item}, _32_)
end
local function switch(dir)
  local from = realpath(vim.fn.getcwd())
  local to = realpath(dir)
  if ((from ~= to) and session["clearable?"]()) then
    session.save()
    session.clear()
    vim.cmd.cd(vim.fn.fnameescape(to))
    require("persistence").load()
    return vim.api.nvim_exec_autocmds("User", {pattern = "WorktreeSwitched", data = {from = from, to = to}})
  else
    return nil
  end
end
local function find_files(dir)
  return LazyVim.pick.open("files", {cwd = dir})
end
return {list = list, pick = pick, switch = switch, ["find-files"] = find_files, info = info}
