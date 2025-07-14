-- [nfnl] Compiled from lua/plugins/fold.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local _local_2_ = autoload("nfnl.core")
local get = _local_2_["get"]
local concat = _local_2_["concat"]
local ufo = autoload("ufo")
local ts_provider = autoload("ufo.provider.treesitter")
local foldingrange = autoload("ufo.model.foldingrange")
local ft__3equery = {typescript = "(call_expression\n      function: (identifier) @_fn\n      (#match? @_fn \"^(test|it|beforeEach|afterEach)$\")) @fold.test\n\n    [(function_declaration)\n     (method_definition)\n     (generator_function_declaration)] @fold.custom", yaml = "(block_mapping_pair\n      key: (_ (_ (string_scalar) @service_key))\n      value: (_ (_ (block_mapping_pair) @fold.custom))\n      (#eq? @service_key \"services\"))", clojure = "(list_lit\n      . (sym_lit name: (sym_name) @_fn)\n      (#match? @_fn \"^(deftest-?|use-fixtures|defn-?|defmethod|defmacro)$\")) @fold.custom"}
--[[ (do (each [ft query (pairs ft->query)] (vim.treesitter.query.parse ft query)) (print "Success! 🎉")) ]]
local function query_folds(bufnr, ft__3equery0)
  local ft = vim.api.nvim_get_option_value("filetype", {buf = bufnr})
  local query_str = get(ft__3equery0, ft)
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
local function treesitter_2bqueries(ft__3equery0)
  local function _8_(bufnr)
    local ranges = concat({}, ts_provider.getFolds(bufnr), query_folds(bufnr, ft__3equery0))
    foldingrange.sortRanges(ranges)
    return ranges
  end
  return _8_
end
local function _9_()
  vim.opt.foldenable = true
  vim.opt.foldcolumn = "0"
  vim.opt.foldlevel = 99
  vim.opt.foldlevelstart = 99
  vim.opt.foldopen = ""
  local function _10_(_bufnr, _filetype, _buftype)
    return {treesitter_2bqueries(ft__3equery), "indent"}
  end
  return ufo.setup({provider_selector = _10_, open_fold_hl_timeout = 100, close_fold_kinds_for_ft = {default = {"fold.custom", "fold.test"}, fennel = {"fn_form", "fold.custom", "fold.test"}}})
end
local function _11_()
  return ufo.openAllFolds()
end
local function _12_()
  return ufo.closeAllFolds()
end
return {{"kevinhwang91/nvim-ufo", dependencies = {"kevinhwang91/promise-async"}, config = _9_, keys = {{"zR", _11_, mode = {"n"}, desc = "Open All Folds"}, {"zM", _12_, mode = {"n"}, desc = "Close All Folds"}}, lazy = false}}
