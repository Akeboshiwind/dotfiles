-- [nfnl] Compiled from lua/plugins/copilot.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local copilot = autoload("copilot")
local copilot_cmd = autoload("copilot.command")
local function _2_()
  return copilot.setup({panel = {enabled = false}, suggestion = {enabled = false}})
end
return {{"zbirenbaum/copilot-cmp", opts = {}}, {"zbirenbaum/copilot.lua", event = "VeryLazy", dependencies = {"zbirenbaum/copilot-cmp"}, config = _2_}}
