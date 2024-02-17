-- [nfnl] Compiled from lua/plugins/lang/python.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local _local_2_ = autoload("nfnl.core")
local update = _local_2_["update"]
return {{"williamboman/mason.nvim", opts = {["ensure-installed"] = {black = true, isort = true}}}, {"stevearc/conform.nvim", opts = {formatters_by_ft = {python = {"black", "isort"}}}}, {"neovim/nvim-lspconfig", opts = {servers = {pylsp = {}}}}}
