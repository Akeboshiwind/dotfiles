-- [nfnl] lua/plugins/worktree.fnl
local function loud()
  return {bg = Snacks.util.color("DiagnosticWarn"), fg = Snacks.util.color("Normal", "bg"), gui = "bold"}
end
local function dashboard_label()
  local info = require("config.worktree").info()
  if info then
    local _1_
    if info["linked?"] then
      _1_ = "DiagnosticWarn"
    else
      _1_ = "Comment"
    end
    return {text = {{info.name, hl = _1_}}, align = "center", padding = 1}
  else
    return nil
  end
end
local function _4_(_, opts)
  local worktree = require("config.worktree")
  local function _5_()
    return worktree.info().name
  end
  local function _6_()
    return (nil ~= worktree.info())
  end
  local function _7_()
    if worktree.info()["linked?"] then
      return loud()
    else
      return nil
    end
  end
  return table.insert(opts.sections.lualine_b, 1, {_5_, cond = _6_, color = _7_})
end
return {{"nvim-lualine/lualine.nvim", opts = _4_}, {"snacks.nvim", opts = {dashboard = {sections = {{section = "header"}, dashboard_label, {section = "keys", gap = 1, padding = 1}, {section = "startup"}}}}}}
