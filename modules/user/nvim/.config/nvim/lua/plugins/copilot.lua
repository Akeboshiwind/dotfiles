-- [nfnl] lua/plugins/copilot.fnl
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
return {{"zbirenbaum/copilot-cmp", opts = {}}, {"zbirenbaum/copilot.lua", event = "VeryLazy", dependencies = {"zbirenbaum/copilot-cmp"}, opts = {panel = {enabled = false}, suggestion = {enabled = false}}}}
