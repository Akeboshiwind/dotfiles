-- [nfnl] lua/plugins/fold.fnl
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local ufo = autoload("ufo")
local function _2_()
  vim.opt.foldenable = true
  vim.opt.foldcolumn = "0"
  vim.opt.foldlevel = 99
  vim.opt.foldlevelstart = 99
  vim.opt.foldopen = ""
  local function _3_(_bufnr, _filetype, _buftype)
    return {"treesitter", "indent"}
  end
  return ufo.setup({provider_selector = _3_, open_fold_hl_timeout = 100, close_fold_kinds_for_ft = {default = {"function_definition", "function_declaration", "method_definition"}}})
end
local function _4_()
  return ufo.openAllFolds()
end
local function _5_()
  return ufo.closeAllFolds()
end
return {{"kevinhwang91/nvim-ufo", dependencies = {"kevinhwang91/promise-async"}, config = _2_, keys = {{"zR", _4_, mode = {"n"}, desc = "Open All Folds"}, {"zM", _5_, mode = {"n"}, desc = "Close All Folds"}}, lazy = false}}
