-- [nfnl] lua/plugins/worktree.fnl
local function loud()
  return {bg = Snacks.util.color("DiagnosticWarn"), fg = Snacks.util.color("Normal", "bg"), gui = "bold"}
end
local function _1_(_, opts)
  local worktree = require("config.worktree")
  local function _2_()
    return worktree.info().name
  end
  local function _3_()
    return (nil ~= worktree.info())
  end
  local function _4_()
    if worktree.info()["linked?"] then
      return loud()
    else
      return nil
    end
  end
  return table.insert(opts.sections.lualine_b, 1, {_2_, cond = _3_, color = _4_})
end
return {{"nvim-lualine/lualine.nvim", opts = _1_}}
