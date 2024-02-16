-- [nfnl] Compiled from lua/plugins/copilot.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local copilot_cmp = autoload("copilot_cmp")
local function _2_()
  return copilot_cmp.setup()
end
return {{"zbirenbaum/copilot-cmp", config = _2_}, {"zbirenbaum/copilot.lua", event = "VeryLazy", dependencies = {"zbirenbaum/copilot-cmp"}, opts = {panel = {enabled = false}, suggestion = {enabled = false}}}}
