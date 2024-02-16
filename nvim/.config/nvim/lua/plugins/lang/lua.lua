-- [nfnl] Compiled from lua/plugins/lang/lua.fnl by https://github.com/Olical/nfnl, do not edit.
local function _1_(_, opts)
  opts.ensure_installed = (opts.ensure_installed or {})
  vim.list_extend(opts.ensure_installed, {"stylua"})
  return opts
end
return {{"williamboman/mason.nvim", opts = _1_}, {"stevearc/conform.nvim", opts = {formatters_by_ft = {lua = {"stylua"}}, formatters = {stylua = {prepend_args = {"--config-path", (vim.fn.stdpath("config") .. "/config/stylua.toml")}}}}}}
