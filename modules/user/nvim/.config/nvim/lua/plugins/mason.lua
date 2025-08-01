-- [nfnl] lua/plugins/mason.fnl
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local fun = autoload("vend.luafun")
local mason = autoload("mason")
local mason_lspconfig = autoload("mason-lspconfig")
local mr = autoload("mason-registry")
local function _2_(_, opts)
  mason.setup(opts)
  mason_lspconfig.setup(opts["mason-lspconfig"])
  local function _3_()
    local function _4_(_2410)
      return _2410:install()
    end
    local function _5_(_2410)
      return not _2410:is_installed()
    end
    local function _6_(tool, _install_3f)
      return mr.get_package(tool)
    end
    local function _7_(_tool, install_3f)
      return install_3f
    end
    return fun.each(_4_, fun.filter(_5_, fun.map(_6_, fun.filter(_7_, fun.iter(opts["ensure-installed"])))))
  end
  return mr.refresh(_3_)
end
return {{"mason-org/mason.nvim", dependencies = {"mason-org/mason-lspconfig.nvim"}, opts = {["ensure-installed"] = {}, ["mason-lspconfig"] = {}}, config = _2_}}
