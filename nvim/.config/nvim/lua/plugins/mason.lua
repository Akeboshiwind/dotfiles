-- [nfnl] Compiled from lua/plugins/mason.fnl by https://github.com/Olical/nfnl, do not edit.
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
    return (_241 or {})
  end
  local function _6_(_241)
    return merge(_241, {automatic_installation = true})
  end
  return update(update(update(opts, "ensure-installed", _4_), "mason-lspconfig", _5_), "mason-lspconfig", _6_)
end
local function _7_(_, opts)
  local mason = require("mason")
  local mason_lspconfig = require("mason-lspconfig")
  local mr = require("mason-registry")
  mason.setup(opts)
  mason_lspconfig.setup(opts["mason-lspconfig"])
  local function _8_()
    for _0, tool in ipairs(opts["ensure-installed"]) do
      local p = mr.get_package(tool)
      if not p:is_installed() then
        p:install()
      else
      end
    end
    return nil
  end
  return mr.refresh(_8_)
end
return {{"williamboman/mason.nvim", dependencies = {"williamboman/mason-lspconfig.nvim"}, opts = _3_, config = _7_}}
