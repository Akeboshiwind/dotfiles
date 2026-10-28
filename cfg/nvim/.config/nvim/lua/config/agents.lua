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
return {list = list}
