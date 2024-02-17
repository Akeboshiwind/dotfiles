-- [nfnl] Compiled from lua/plugins/lang/fennel.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local _local_2_ = autoload("nfnl.core")
local update = _local_2_["update"]
local lspconfig = require("lspconfig")
return {{"Olical/nfnl", ft = "fennel"}, {"Olical/conjure", ft = {"fennel"}}, {"williamboman/mason.nvim", opts = {["ensure-installed"] = {["fennel-language-server"] = true}}}, {"neovim/nvim-lspconfig", opts = {servers = {fennel_language_server = {filetypes = {"fennel"}, root_dir = lspconfig.util.root_pattern("lua", "fnl"), single_file_support = true, settings = {fennel = {diagnostics = {globals = {"vim", "jit", "comment"}}, workspace = {library = vim.api.nvim_list_runtime_paths()}}}}}}}}
