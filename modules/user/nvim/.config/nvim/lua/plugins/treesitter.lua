-- [nfnl] lua/plugins/treesitter.fnl
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local ts = autoload("nvim-treesitter")
local Set = autoload("util.set")
local function _2_(_, opts)
  local available = Set.from(ts.get_available())
  ts.install(opts.ensure_installed)
  for lang, _0 in pairs(available) do
    local function _3_(ev)
      local function _4_()
        return vim.treesitter.start(ev.buf, lang)
      end
      return ts.install(lang):await(_4_)
    end
    vim.api.nvim_create_autocmd("FileType", {pattern = vim.treesitter.language.get_filetypes(lang), callback = _3_})
  end
  return nil
end
return {{"nvim-treesitter/nvim-treesitter", branch = "main", build = ":TSUpdate", opts = {ensure_installed = {"comment", "regex"}}, config = _2_, lazy = false}}
