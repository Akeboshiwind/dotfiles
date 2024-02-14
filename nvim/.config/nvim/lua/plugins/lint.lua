-- [nfnl] Compiled from fnl/plugins/lint.fnl by https://github.com/Olical/nfnl, do not edit.
local util = require("util")
local function _1_(_, opts)
  opts.ensure_installed = (opts.ensure_installed or {})
  return vim.list_extend(opts.ensure_installed, {"commitlint"})
end
local function _2_(_, opts)
  local lint = require("lint")
  for name, linter in pairs(opts.linters) do
    if (("table" == type(linter)) and ("table" == type(lint.linters[name]))) then
      lint.linters[name] = vim.tbl_deep_extend("force", lint.linters[name], linter)
    else
      lint.linters[name] = linter
    end
  end
  lint.linters_by_ft = opts.linters_by_ft
  local function _4_()
    return lint.try_lint()
  end
  return vim.api.nvim_create_autocmd(opts.events, {group = vim.api.nvim_create_augroup("nvim-lint", {clear = true}), callback = util.debounce(100, _4_)})
end
return {{"williamboman/mason.nvim", opts = _1_}, {"mfussenegger/nvim-lint", opts = {events = {"BufWritePost", "BufReadPost", "InsertLeave"}, linters_by_ft = {gitcommit = {"commitlint"}}, linters = {commitlint = {args = {"--config", (vim.fn.stdpath("config") .. "/config/commitlint.config.js"), "--extends", (vim.fn.stdpath("data") .. "/mason/packages/commitlint/node_modules/@commitlint/config-conventional")}}}}, config = _2_}}
