-- [nfnl] Compiled from lua/plugins/lang/lua.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local _local_2_ = autoload("nfnl.core")
local update = _local_2_["update"]
return {{"williamboman/mason.nvim", opts = {["ensure-installed"] = {stylua = true}}}, {"stevearc/conform.nvim", opts = {formatters_by_ft = {lua = {"stylua"}}, formatters = {stylua = {prepend_args = {"--config-path", (vim.fn.stdpath("config") .. "/config/stylua.toml")}}}}}}
