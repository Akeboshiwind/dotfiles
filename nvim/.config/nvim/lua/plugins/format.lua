-- [nfnl] Compiled from lua/plugins/format.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local _local_2_ = autoload("nfnl.core")
local get = _local_2_["get"]
local assoc = _local_2_["assoc"]
local conform = autoload("conform")
local function _3_()
  return conform.format()
end
local function _4_(_, opts)
  local format_on_save = get(opts, "format_on_save", {})
  local function _5_(_241)
    local ft = vim.api.nvim_buf_get_option(_241, "filetype")
    if not get(opts.no_format_on_save, ft) then
      _G.P("format_on_save")
      return format_on_save
    else
      return nil
    end
  end
  return conform.setup(assoc(opts, "format_on_save", _5_))
end
return {{"stevearc/conform.nvim", event = {"BufWritePre"}, cmd = {"ConformInfo"}, keys = {{"<leader>F", _3_, desc = "Format buffer"}}, opts = {formatters_by_ft = {}, formatters = {}, no_format_on_save = {}, format_on_save = {lsp_fallback = true, timeout_ms = 500}}, config = _4_}}
