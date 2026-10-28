-- [nfnl] lua/config/agents.fnl
local function realpath(path)
  return (vim.uv.fs_realpath(path) or path)
end
local function list()
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
    local tbl_26_ = {}
    local i_27_ = 0
    for _, row in ipairs(rows) do
      local val_28_
      do
        row["cwd"] = realpath(row.cwd)
        val_28_ = row
      end
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    return tbl_26_
  else
    return {}
  end
end
local function format_item(agent)
  return ((agent.state or "") .. "  " .. agent.name .. "  " .. vim.fn.fnamemodify(agent.cwd, ":~"))
end
local function pick(prompt, on_choice)
  local _5_
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for _, agent in ipairs(list()) do
      local val_28_
      if vim.uv.fs_stat(agent.cwd) then
        val_28_ = agent
      else
        val_28_ = nil
      end
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    _5_ = tbl_26_
  end
  local function _8_(_241)
    if _241 then
      return on_choice(_241.cwd)
    else
      return nil
    end
  end
  return vim.ui.select(_5_, {prompt = prompt, format_item = format_item}, _8_)
end
return {list = list, pick = pick}
