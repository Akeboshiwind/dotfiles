-- [nfnl] Compiled from lua/plugins/treesitter.fnl by https://github.com/Olical/nfnl, do not edit.
--[[ {1 "nvim-treesitter/playground" :cmd "TSPlaygroundToggle"} ]]
local function _1_(_, opts)
  local _let_2_ = require("nvim-treesitter.configs")
  local setup = _let_2_["setup"]
  return setup(opts)
end
return {{"nvim-treesitter/nvim-treesitter", build = ":TSUpdate", dependencies = {nil}, opts = {ensure_installed = {"comment", "regex"}, auto_install = true, highlight = {enable = true}, indent = {enable = false}, query_linter = {enable = true, use_virtual_text = true, lint_events = {"BufWrite", "CursorHold"}}}, config = _1_}}
