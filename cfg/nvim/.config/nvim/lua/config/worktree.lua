-- [nfnl] lua/config/worktree.fnl
local session = require("config.session")
local function realpath(path)
  return (vim.uv.fs_realpath(path) or path)
end
local function live_agents()
  local ran_3f, result
  local function _1_()
    return vim.system({"claude", "agents", "--json"}, {text = true}):wait(2000)
  end
  ran_3f, result = pcall(_1_)
  local parsed_3f, rows
  if (ran_3f and (0 == result.code)) then
    parsed_3f, rows = pcall(vim.json.decode, result.stdout)
  else
    parsed_3f, rows = false
  end
  if parsed_3f then
    local tbl_21_ = {}
    for _, row in ipairs(rows) do
      local k_22_, v_23_ = realpath(row.cwd), row.name
      if ((k_22_ ~= nil) and (v_23_ ~= nil)) then
        tbl_21_[k_22_] = v_23_
      else
      end
    end
    return tbl_21_
  else
    return {}
  end
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
local function list(_3fagents)
  local agents = (_3fagents or live_agents())
  local cwd = realpath(vim.fn.getcwd())
  local result = vim.system({"git", "worktree", "list", "--porcelain"}, {text = true}):wait()
  if (0 ~= result.code) then
    return {}
  else
    local tbl_26_ = {}
    local i_27_ = 0
    for _, block in ipairs(vim.split(result.stdout, "\n\n", {trimempty = true})) do
      local val_28_
      do
        local item = parse_worktree(block)
        if not item.prunable then
          item["name"] = vim.fs.basename(item.path)
          item["agent"] = agents[item.path]
          item["current?"] = (item.path == cwd)
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
    return tbl_26_
  end
end
local function format_item(item)
  local _9_
  if item["current?"] then
    _9_ = "* "
  else
    _9_ = "  "
  end
  local _11_
  if item.branch then
    _11_ = ("  [" .. item.branch .. "]")
  else
    _11_ = ""
  end
  local _13_
  if item.agent then
    _13_ = ("  " .. item.agent)
  else
    _13_ = ""
  end
  return (_9_ .. item.name .. _11_ .. _13_)
end
local function pick(prompt, on_choice)
  local function _15_(_241)
    if _241 then
      return on_choice(_241.path)
    else
      return nil
    end
  end
  return vim.ui.select(list(), {prompt = prompt, format_item = format_item}, _15_)
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
local function read_info(dir)
  local result = vim.system({"git", "rev-parse", "--path-format=absolute", "--show-toplevel", "--git-dir", "--git-common-dir"}, {text = true, cwd = dir}):wait()
  if (0 == result.code) then
    local _let_18_ = vim.split(result.stdout, "\n", {trimempty = true})
    local top = _let_18_[1]
    local git_dir = _let_18_[2]
    local common_dir = _let_18_[3]
    return {name = vim.fs.basename(top), ["linked?"] = (git_dir ~= common_dir)}
  else
    return false
  end
end
local infos = {}
local function info()
  local cwd = vim.fn.getcwd()
  if (nil == infos[cwd]) then
    infos[cwd] = read_info(cwd)
  else
  end
  return (infos[cwd] or nil)
end
return {list = list, pick = pick, switch = switch, ["find-files"] = find_files, info = info}
