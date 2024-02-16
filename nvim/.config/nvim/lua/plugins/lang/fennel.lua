-- [nfnl] Compiled from lua/plugins/lang/fennel.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local _local_2_ = autoload("nfnl.core")
local update = _local_2_["update"]
local lspconfig = require("lspconfig")
local function _3_(_, opts)
  local function _4_(_241)
    return (_241 or {})
  end
  local function _5_(_241)
    return vim.list_extend(_241, {"fennel-language-server"})
  end
  return update(update(opts, "ensure-installed", _4_), "ensure-installed", _5_)
end
return {{"Olical/nfnl", ft = "fennel"}, {"Olical/conjure", ft = {"fennel"}}, {"williamboman/mason.nvim", opts = _3_}, {"neovim/nvim-lspconfig", opts = {servers = {fennel_language_server = {filetypes = {"fennel"}, root_dir = lspconfig.util.root_pattern("lua", "fnl"), single_file_support = true, settings = {fennel = {diagnostics = {globals = {"vim", "jit", "comment"}}, workspace = {library = vim.api.nvim_list_runtime_paths()}}}}}}}}
