-- [nfnl] lua/plugins/format.fnl
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local _local_2_ = autoload("nfnl.core")
local get = _local_2_["get"]
local assoc = _local_2_["assoc"]
local conform = autoload("conform")
local cfg = autoload("util.cfg")
local create_command = vim.api.nvim_create_user_command
local enabled = true
local function _3_()
  enabled = false
  return print("Conform formatting disabled")
end
create_command("ConformOff", _3_, {desc = "Disable Conform Formatting"})
local function _4_()
  enabled = true
  return print("Conform formatting enabled")
end
create_command("ConformOn", _4_, {desc = "Enable Conform Formatting"})
local function _5_()
  return conform.format()
end
local function _6_(_, opts, G)
  local format_on_save = (opts.format_on_save or {})
  local no_format_on_save = cfg["merge-all"](G["format/no-on-save"])
  local format_on_save_fn
  local function _7_(_241)
    local ft = vim.api.nvim_buf_get_option(_241, "filetype")
    if (enabled and not get(no_format_on_save, ft)) then
      return format_on_save
    else
      return nil
    end
  end
  format_on_save_fn = _7_
  return conform.setup(assoc(assoc(assoc(opts, "format_on_save", format_on_save_fn), "formatters_by_ft", cfg["merge-all"](G["format/by-ft"])), "formatters", cfg["merge-all"](G["format/formatters"])))
end
return {{"stevearc/conform.nvim", event = {"BufWritePre"}, cmd = {"ConformInfo"}, keys = {{"<leader>F", _5_, desc = "Format buffer"}}, ["format/by-ft"] = {}, ["format/formatters"] = {}, ["format/no-on-save"] = {}, opts = {format_on_save = {lsp_fallback = true, timeout_ms = 500}}, config = _6_}}
