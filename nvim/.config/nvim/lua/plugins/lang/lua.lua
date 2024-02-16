-- [nfnl] Compiled from lua/plugins/lang/lua.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local _local_2_ = autoload("nfnl.core")
local update = _local_2_["update"]
local merge = _local_2_["merge"]
local function _3_(_, opts)
  local function _4_(_241)
    return (_241 or {})
  end
  local function _5_(_241)
    return vim.list_extend(_241, {"stylua"})
  end
  return update(update(opts, "ensure-installed", _4_), "ensure-installed", _5_)
end
return {{"williamboman/mason.nvim", opts = _3_}, {"stevearc/conform.nvim", opts = {formatters_by_ft = {lua = {"stylua"}}, formatters = {stylua = {prepend_args = {"--config-path", (vim.fn.stdpath("config") .. "/config/stylua.toml")}}}}}}
