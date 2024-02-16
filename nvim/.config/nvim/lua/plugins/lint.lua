-- [nfnl] Compiled from lua/plugins/lint.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local util = autoload("util")
local _local_2_ = autoload("nfnl.core")
local update = _local_2_["update"]
local merge = _local_2_["merge"]
local function _3_(_, opts)
  local function _4_(_241)
    return (_241 or {})
  end
  local function _5_(_241)
    return vim.list_extend(_241, {"commitlint"})
  end
  return update(update(opts, "ensure-installed", _4_), "ensure-installed", _5_)
end
local function _6_(_, opts)
  local lint = require("lint")
  for name, linter in pairs(opts.linters) do
    if (("table" == type(linter)) and ("table" == type(lint.linters[name]))) then
      lint.linters[name] = vim.tbl_deep_extend("force", lint.linters[name], linter)
    else
      lint.linters[name] = linter
    end
  end
  lint.linters_by_ft = opts.linters_by_ft
  local function try_lint()
    local names = lint._resolve_linter_by_ft(vim.bo.filetype)
    if (0 ~= #names) then
      vim.list_extend(names, (lint.linters_by_ft._ or {}))
    else
    end
    vim.list_extend(names, (lint.linters_by_ft["*"] or {}))
    do
      local filename = vim.api.nvim_buf_get_name(0)
      local ctx = {filename = filename, dirname = vim.fn.fnamemodify(filename, ":h")}
      local function _9_(name)
        local linter = lint.linters[name]
        return (linter and not ((type(linter) == "table") and linter.condition and not linter.condition(ctx)))
      end
      names = vim.tbl_filter(_9_, names)
    end
    if (0 ~= #names) then
      return lint.try_lint(names)
    else
      return nil
    end
  end
  local function _11_()
    return try_lint()
  end
  return vim.api.nvim_create_autocmd(opts.events, {group = vim.api.nvim_create_augroup("nvim-lint", {clear = true}), callback = util.debounce(100, _11_)})
end
return {{"williamboman/mason.nvim", opts = _3_}, {"mfussenegger/nvim-lint", opts = {events = {"BufWritePost", "BufReadPost", "InsertLeave"}, linters_by_ft = {gitcommit = {"commitlint"}}, linters = {commitlint = {args = {"--config", (vim.fn.stdpath("config") .. "/config/commitlint.config.js"), "--extends", (vim.fn.stdpath("data") .. "/mason/packages/commitlint/node_modules/@commitlint/config-conventional")}}}}, config = _6_}}
