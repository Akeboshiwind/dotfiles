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
return {{"nvim-telescope/telescope.nvim", opts = {defaults = {mappings = {i = {["<C-j>"] = _1_, ["<C-k>"] = _2_, ["<C-h>"] = _3_}}}}}}
