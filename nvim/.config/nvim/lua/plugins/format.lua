-- [nfnl] Compiled from lua/plugins/format.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local conform = autoload("conform")
local function _2_()
  return conform.format()
end
return {{"stevearc/conform.nvim", event = {"BufWritePre"}, cmd = {"ConformInfo"}, keys = {{"<leader>F", _2_, desc = "Format buffer"}}, opts = {formatters_by_ft = {}, formatters = {}}}}
