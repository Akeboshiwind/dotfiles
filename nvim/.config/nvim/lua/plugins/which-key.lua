-- [nfnl] Compiled from lua/plugins/which-key.fnl by https://github.com/Olical/nfnl, do not edit.
local function _1_()
  vim.opt.timeoutlen = 400
  return nil
end
local function _2_(_, opts)
  local wk = require("which-key")
  wk.setup(opts)
  return wk.register(opts.defaults)
end
return {{"folke/which-key.nvim", init = _1_, event = "VeryLazy", keys = {{"fd", "<ESC>", desc = "Quick Escape", mode = "i"}, {"*", "g*", desc = "Search in buffer for match"}, {"#", "g#", desc = "Search in buffer for match, backwards"}, {"<leader>x", "<cmd>luafile %<CR>", desc = "Source lua buffer"}, {"<leader>X", "<cmd>source %<CR>", desc = "Source vim buffer"}, {"<leader>w=", "<cmd>wincmd =<CR>", desc = "Equalise all windows"}, {"<leader>w+", "<cmd>wincmd +<CR>", desc = "Increase window height"}, {"<leader>w-", "<cmd>wincmd -<CR>", desc = "Decrease window height"}, {"<leader>w>", "<cmd>wincmd <<CR>", desc = "Increase window width"}, {"<leader>w<", "<cmd>wincmd ><CR>", desc = "Decrease window width"}, {"<C-Space>", "<cmd>:WhichKey ''<CR>", desc = "Show base commands"}}, opts = {plugins = {spelling = true}, triggers_blacklist = {i = {"f"}}, defaults = {["<leader>w"] = {name = "window"}}}, config = _2_}}
