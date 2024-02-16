-- [nfnl] Compiled from lua/util/set.fnl by https://github.com/Olical/nfnl, do not edit.
local function new()
  return {}
end
local function contains_3f(s, v)
  return s[v]
end
local function insert_21(s, v)
  s[v] = true
  return nil
end
local function remove_21(s, v)
  s[v] = nil
  return nil
end
return {new = new, ["contains?"] = contains_3f, ["insert!"] = insert_21, ["remove!"] = remove_21}
