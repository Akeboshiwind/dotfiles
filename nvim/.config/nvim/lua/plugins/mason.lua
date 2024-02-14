-- [nfnl] Compiled from fnl/plugins/mason.fnl by https://github.com/Olical/nfnl, do not edit.
local function _1_(_, opts)
  opts.ensure_installed = (opts.ensure_installed or {})
  opts.mason_lspconfig = (opts.mason_lspconfig or {automatic_installation = true})
  return opts
end
local function _2_(_, opts)
  do end (require("mason")).setup(opts)
  do end (require("mason-lspconfig")).setup(opts.mason_lspconfig)
  local mr = require("mason-registry")
  local function _3_()
    for _0, tool in ipairs(opts.ensure_installed) do
      local p = mr.get_package(tool)
      if not p:is_installed() then
        p:install()
      else
      end
    end
    return nil
  end
  return mr.refresh(_3_)
end
return {{"williamboman/mason.nvim", dependencies = {"williamboman/mason-lspconfig.nvim"}, opts = _1_, config = _2_}}
