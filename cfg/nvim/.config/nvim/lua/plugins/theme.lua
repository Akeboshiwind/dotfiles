-- [nfnl] lua/plugins/theme.fnl
local work_dir = os.getenv("HOME")
local cwd = vim.fn.getcwd()
local theme
if string.find(cwd, (work_dir .. "/prog/work"), 1, true) then
  theme = "kanagawa-dragon"
else
  theme = "kanagawa-wave"
end
local function _2_()
  return {["@comment.todo"] = {link = "@comment.note"}}
end
return {{"rebelot/kanagawa.nvim", opts = {dimInactive = true, overrides = _2_}}, {"p00f/alabaster.nvim"}, {"LazyVim/LazyVim", opts = {colorscheme = theme}}, {"folke/which-key.nvim", opts = {preset = "modern"}}, {"snacks.nvim", opts = {indent = {enabled = false}}}}
