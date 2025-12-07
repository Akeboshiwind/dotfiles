-- [nfnl] lua/plugins/theme.fnl
local function _1_()
  return {["@comment.todo"] = {link = "@comment.note"}}
end
return {{"rebelot/kanagawa.nvim", opts = {dimInactive = true, overrides = _1_}}, {"p00f/alabaster.nvim"}, {"LazyVim/LazyVim", opts = {colorscheme = "alabaster"}}, {"folke/which-key.nvim", opts = {preset = "modern"}}, {"snacks.nvim", opts = {indent = {enabled = false}}}}
