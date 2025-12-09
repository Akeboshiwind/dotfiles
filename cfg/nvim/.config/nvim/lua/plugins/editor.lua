-- [nfnl] lua/plugins/editor.fnl
local telescope_actions = require("telescope.actions")
local function _1_(...)
  return telescope_actions.move_selection_next(...)
end
local function _2_(...)
  return telescope_actions.move_selection_previous(...)
end
local function _3_(...)
  return telescope_actions.which_key(...)
end
return {{"chrisgrieser/nvim-spider", keys = {{"w", "<cmd>lua require('spider').motion('w')<CR>", mode = {"n", "o", "x"}}, {"e", "<cmd>lua require('spider').motion('e')<CR>", mode = {"n", "o", "x"}}, {"b", "<cmd>lua require('spider').motion('b')<CR>", mode = {"n", "o", "x"}}}}, {"nvim-telescope/telescope.nvim", opts = {defaults = {mappings = {i = {["<C-j>"] = _1_, ["<C-k>"] = _2_, ["<C-h>"] = _3_}}}}}}
