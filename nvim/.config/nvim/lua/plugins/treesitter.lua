-- [nfnl] Compiled from lua/plugins/treesitter.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local nvim_treesitter_config = autoload("nvim-treesitter.configs")
--[[ {1 "nvim-treesitter/playground" :cmd "TSPlaygroundToggle"} ]]
local function _2_(_, opts)
  return nvim_treesitter_config.setup(opts)
end
return {{"nvim-treesitter/nvim-treesitter", build = ":TSUpdate", dependencies = {nil}, opts = {ensure_installed = {"comment", "regex"}, auto_install = true, highlight = {enable = true}, indent = {enable = false}, query_linter = {enable = true, use_virtual_text = true, lint_events = {"BufWrite", "CursorHold"}}}, config = _2_}}
