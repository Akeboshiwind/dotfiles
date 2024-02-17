-- [nfnl] Compiled from lua/plugins/mason.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local _local_2_ = autoload("nfnl.core")
local update = _local_2_["update"]
local merge = _local_2_["merge"]
local mason = autoload("mason")
local mason_lspconfig = autoload("mason-lspconfig")
local mr = autoload("mason-registry")
local function _3_(_, opts)
  mason.setup(opts)
  mason_lspconfig.setup(opts["mason-lspconfig"])
  local function _4_()
    for tool, install_3f in pairs(opts["ensure-installed"]) do
      if install_3f then
        local p = mr.get_package(tool)
        if not p:is_installed() then
          p:install()
        else
        end
      else
      end
    end
    return nil
  end
  return mr.refresh(_4_)
end
return {{"williamboman/mason.nvim", dependencies = {"williamboman/mason-lspconfig.nvim"}, opts = {["ensure-installed"] = {}, ["mason-lspconfig"] = {automatic_installation = true}}, config = _3_}}
