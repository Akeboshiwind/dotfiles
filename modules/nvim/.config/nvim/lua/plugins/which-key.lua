-- [nfnl] Compiled from lua/plugins/which-key.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local wk = autoload("which-key")
local function _2_()
  vim.opt.timeoutlen = 400
  return nil
end
local function _3_()
  return wk.show({global = false})
end
local function _4_(_, opts)
  wk.setup(opts)
  return wk.add({{"<leader>w", group = "window"}})
end
return {{"folke/which-key.nvim", init = _2_, event = "VeryLazy", keys = {{"fd", "<ESC>", desc = "Quick Escape", mode = "i"}, {"*", "g*", desc = "Search in buffer for match"}, {"#", "g#", desc = "Search in buffer for match, backwards"}, {"<leader>?", _3_, desc = "Buffer Local Keymaps"}, {"<leader>x", "<cmd>luafile %<CR>", desc = "Source lua buffer"}, {"<leader>X", "<cmd>source %<CR>", desc = "Source vim buffer"}, {"<leader>w=", "<cmd>wincmd =<CR>", desc = "Equalise all windows"}, {"<leader>w+", "<cmd>wincmd +<CR>", desc = "Increase window height"}, {"<leader>w-", "<cmd>wincmd -<CR>", desc = "Decrease window height"}, {"<leader>w>", "<cmd>wincmd <<CR>", desc = "Increase window width"}, {"<leader>w<", "<cmd>wincmd ><CR>", desc = "Decrease window width"}, {"<C-Space>", "<cmd>:WhichKey ''<CR>", desc = "Show base commands"}}, opts = {notify = false}, config = _4_}}
