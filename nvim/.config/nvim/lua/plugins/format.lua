-- [nfnl] Compiled from lua/plugins/format.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local _local_2_ = autoload("nfnl.core")
local get = _local_2_["get"]
local assoc = _local_2_["assoc"]
local conform = autoload("conform")
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
local function _6_(_, opts)
  local format_on_save = get(opts, "format_on_save", {})
  local function _7_(_241)
    local ft = vim.api.nvim_buf_get_option(_241, "filetype")
    if (enabled and not get(opts.no_format_on_save, ft)) then
      return format_on_save
    else
      return nil
    end
  end
  return conform.setup(assoc(opts, "format_on_save", _7_))
end
return {{"stevearc/conform.nvim", event = {"BufWritePre"}, cmd = {"ConformInfo"}, keys = {{"<leader>F", _5_, desc = "Format buffer"}}, opts = {formatters_by_ft = {}, formatters = {}, no_format_on_save = {}, format_on_save = {lsp_fallback = true, timeout_ms = 500}}, config = _6_}}
