-- [nfnl] lua/plugins/fold.fnl
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local _local_2_ = autoload("nfnl.core")
local get = _local_2_["get"]
local concat = _local_2_["concat"]
local merge = _local_2_["merge"]
local ufo = autoload("ufo")
local ts_provider = autoload("ufo.provider.treesitter")
local foldingrange = autoload("ufo.model.foldingrange")
local cfg = autoload("util.cfg")
local function query_folds(bufnr, ft__3equery)
  local ft = vim.api.nvim_get_option_value("filetype", {buf = bufnr})
  local query_str = get(ft__3equery, ft)
  local _, parser = pcall(vim.treesitter.get_parser, bufnr, ft)
  if (query_str and parser) then
    local _let_3_ = parser:parse()
    local tree = _let_3_[1]
    local root = tree:root()
    local ok, query = pcall(vim.treesitter.query.parse, ft, query_str)
    if not ok then
      vim.notify(("Error parsing custom query for " .. ft), vim.log.levels.ERROR)
      return nil
    else
      local tbl = {}
      for id, node in query:iter_captures(root, bufnr) do
        local capture_name = query.captures[id]
        local start, _0, stop, stop_col = node:range()
        local stop0
        if (stop_col == 0) then
          stop0 = (stop - 1)
        else
          stop0 = stop
        end
        if (stop0 > start) then
          table.insert(tbl, foldingrange.new(start, stop0, nil, nil, capture_name))
        else
        end
      end
      return tbl
    end
  else
    return nil
  end
end
local function treesitter_2bqueries(ft__3equery)
  local function _8_(bufnr)
    local ranges = concat({}, ts_provider.getFolds(bufnr), query_folds(bufnr, ft__3equery))
    foldingrange.sortRanges(ranges)
    return ranges
  end
  return _8_
end
local function _9_(_, _0, G)
  vim.opt.foldenable = true
  vim.opt.foldcolumn = "0"
  vim.opt.foldlevel = 99
  vim.opt.foldlevelstart = 99
  vim.opt.foldopen = ""
  local default_close_kinds = {"fold.custom", "fold.test"}
  local close_kinds
  local _10_
  do
    local tbl_16_ = {}
    for lang, kinds in pairs(cfg["merge-all"](G["fold/close-kinds"])) do
      local k_17_, v_18_ = lang, concat(kinds, default_close_kinds)
      if ((k_17_ ~= nil) and (v_18_ ~= nil)) then
        tbl_16_[k_17_] = v_18_
      else
      end
    end
    _10_ = tbl_16_
  end
  close_kinds = merge(_10_, {default = default_close_kinds})
  local function _12_(_bufnr, _filetype, _buftype)
    return {treesitter_2bqueries(cfg["merge-all"](G["fold/queries"])), "indent"}
  end
  return ufo.setup({provider_selector = _12_, open_fold_hl_timeout = 100, close_fold_kinds_for_ft = close_kinds})
end
local function _13_()
  return ufo.openAllFolds()
end
local function _14_()
  return ufo.closeAllFolds()
end
return {{"kevinhwang91/nvim-ufo", dependencies = {"kevinhwang91/promise-async"}, ["fold/queries"] = {}, ["fold/close-kinds"] = {}, config = _9_, keys = {{"zR", _13_, mode = {"n"}, desc = "Open All Folds"}, {"zM", _14_, mode = {"n"}, desc = "Close All Folds"}}, lazy = false}}
