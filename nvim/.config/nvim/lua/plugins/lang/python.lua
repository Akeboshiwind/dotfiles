-- [nfnl] Compiled from fnl/plugins/lang/python.fnl by https://github.com/Olical/nfnl, do not edit.
local function _1_(_, opts)
  opts.ensure_installed = (opts.ensure_installed or {})
  vim.list_extend(opts.ensure_installed, {"black", "isort"})
  return opts
end
return {{"williamboman/mason.nvim", opts = _1_}, {"stevearc/conform.nvim", opts = {formatters_by_ft = {python = {"black", "isort"}}}}, {"neovim/nvim-lspconfig", opts = {servers = {pylsp = {}}}}}
