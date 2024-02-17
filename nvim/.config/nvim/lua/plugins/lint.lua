-- [nfnl] Compiled from lua/plugins/lint.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local _local_2_ = autoload("nfnl.core")
local update = _local_2_["update"]
local kv_pairs = _local_2_["kv-pairs"]
local reduce = _local_2_["reduce"]
local table_3f = _local_2_["table?"]
local get = _local_2_["get"]
local assoc = _local_2_["assoc"]
local util = autoload("util")
local lint = autoload("lint")
local function _3_(_, opts)
  local function _6_(acc, _4_)
    local _arg_5_ = _4_
    local name = _arg_5_[1]
    local linter = _arg_5_[2]
    if (table_3f(linter) and get(acc, name)) then
      local function _7_(_241)
        return vim.tbl_deep_extend("force", _241, linter)
      end
      return update(acc, name, _7_)
    else
      return assoc(acc, name, linter)
    end
  end
  reduce(_6_, lint.linters, kv_pairs(opts.linters))
  assoc(lint, "linters_by_ft", opts.linters_by_ft)
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
      local function _10_(name)
        local linter = lint.linters[name]
        return (linter and not ((type(linter) == "table") and linter.condition and not linter.condition(ctx)))
      end
      names = vim.tbl_filter(_10_, names)
    end
    if (0 ~= #names) then
      return lint.try_lint(names)
    else
      return nil
    end
  end
  local function _12_()
    return try_lint()
  end
  return vim.api.nvim_create_autocmd(opts.events, {group = vim.api.nvim_create_augroup("nvim-lint", {clear = true}), callback = util.debounce(100, _12_)})
end
return {{"williamboman/mason.nvim", opts = {["ensure-installed"] = {commitlint = true}}}, {"mfussenegger/nvim-lint", opts = {events = {"BufWritePost", "BufReadPost", "InsertLeave"}, linters_by_ft = {gitcommit = {"commitlint"}}, linters = {commitlint = {args = {"--config", (vim.fn.stdpath("config") .. "/config/commitlint.config.js"), "--extends", (vim.fn.stdpath("data") .. "/mason/packages/commitlint/node_modules/@commitlint/config-conventional")}}}}, config = _3_}}
