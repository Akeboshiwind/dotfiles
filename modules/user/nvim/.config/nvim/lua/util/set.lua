-- [nfnl] lua/util/set.fnl
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
local function from(t)
  local ret = new()
  if t then
    for _, v in pairs(t) do
      insert_21(ret, v)
    end
  else
  end
  return ret
end
return {new = new, ["contains?"] = contains_3f, ["insert!"] = insert_21, ["remove!"] = remove_21, from = from}
