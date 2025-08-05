-- [nfnl] lua/plugins/treesitter.fnl
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local ts = autoload("nvim-treesitter")
local Set = autoload("util.set")
local cfg = autoload("util.cfg")
local function _2_(_, _0, G)
  local available = Set.from(ts.get_available())
  ts.install(cfg["flatten-1"](G["treesitter/ensure-installed"]))
  for lang, _1 in pairs(available) do
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
return {{"nvim-treesitter/nvim-treesitter", branch = "main", build = ":TSUpdate", ["treesitter/ensure-installed"] = {"comment", "regex"}, config = _2_, lazy = false}}
