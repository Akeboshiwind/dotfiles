-- [nfnl] lua/config/keymaps.fnl
local map = vim.keymap.set
map("i", "fd", "<ESC>", {desc = "Quick Escape"})
map("n", "<leader>fy", "<cmd>Telescope filetypes<cr>", {desc = "Set filetype"})
local function selected_lines()
  local cursor = vim.fn.line(".")
  local anchor = vim.fn.line("v")
  return {math.min(cursor, anchor), math.max(cursor, anchor)}
end
local function map_hunk(key, action, desc)
  local function _1_()
    return require("gitsigns")[action]()
  end
  map("n", key, _1_, {desc = desc})
  local function _2_()
    return require("gitsigns")[action](selected_lines())
  end
  return map("x", key, _2_, {desc = (desc .. " (selection)")})
end
map_hunk("<leader>hs", "stage_hunk", "Stage hunk")
map_hunk("<leader>hr", "reset_hunk", "Reset hunk")
local function _3_()
  local gitsigns = require("gitsigns")
  return gitsigns.preview_hunk()
end
map("n", "<leader>hp", _3_, {desc = "Preview hunk"})
local function _4_()
  local gitsigns = require("gitsigns")
  local on_3f = gitsigns.toggle_deleted()
  return gitsigns.toggle_word_diff(on_3f)
end
return map("n", "<leader>ho", _4_, {desc = "Toggle diff overlay"})
