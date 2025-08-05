-- [nfnl] lua/util/cfg.fnl
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local _local_2_ = autoload("nfnl.core")
local map = _local_2_["map"]
local filter = _local_2_["filter"]
local update = _local_2_["update"]
local empty_3f = _local_2_["empty?"]
local function flatten_1(coll)
  local t = {}
  for _, item in ipairs(coll) do
    if (type(item) == "table") then
      local tbl_19_ = t
      for _0, v in ipairs(item) do
        local val_20_ = v
        table.insert(tbl_19_, val_20_)
      end
    else
      table.insert(t, item)
    end
  end
  return t
end
local function group_by_key(coll)
  local G = {}
  for _, m in ipairs(coll) do
    local acc = {}
    for k, v in pairs(m) do
      local value = (G[k] or {})
      table.insert(value, v)
      G[k] = value
      acc = G
    end
    G = acc
  end
  return G
end
local function merge_into_21(base, coll)
  if empty_3f(coll) then
    return base
  else
    return vim.tbl_deep_extend("force", base, unpack(coll))
  end
end
local function merge_all(coll)
  return merge_into_21({}, coll)
end
local function ensure_table(config)
  if (type(config) ~= "table") then
    return {config}
  else
    return config
  end
end
local function path__3emodule(path)
  if (nil ~= path) then
    local tmp_3_ = string.match(path, "lua/(.+)%.lua$")
    if (nil ~= tmp_3_) then
      return string.gsub(tmp_3_, "/", ".")
    else
      return nil
    end
  else
    return nil
  end
end
local function find_modules(module, recursively_3f)
  local patt
  local _8_
  if recursively_3f then
    _8_ = "/**/*.lua"
  else
    _8_ = "/*.lua"
  end
  patt = ("lua/" .. string.gsub(module, "%.", "/") .. _8_)
  return map(path__3emodule, vim.api.nvim_get_runtime_file(patt, true))
end
local function wrap_config(config_fn, global_config)
  if (type(config_fn) == "function") then
    local function _10_(plugin, opts)
      return config_fn(plugin, opts, global_config)
    end
    return _10_
  else
    return config_fn
  end
end
local function plugin_3f(m)
  return (m and m[1])
end
local function only(coll)
  assert((1 == #coll), "expected only one value")
  return coll[1]
end
return {["flatten-1"] = flatten_1, ["group-by-key"] = group_by_key, ["merge-into!"] = merge_into_21, ["merge-all"] = merge_all, ["ensure-table"] = ensure_table, ["path->module"] = path__3emodule, ["find-modules"] = find_modules, ["wrap-config"] = wrap_config, ["plugin?"] = plugin_3f, only = only}
