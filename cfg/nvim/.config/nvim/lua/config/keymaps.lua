-- [nfnl] lua/config/keymaps.fnl
local map = vim.keymap.set
map("i", "fd", "<ESC>", {desc = "Quick Escape"})
map("n", "<leader>fy", "<cmd>Telescope filetypes<cr>", {desc = "Set filetype"})
local function _1_()
  local worktree = require("config.worktree")
  return worktree.pick("Switch to worktree", worktree.switch)
end
map("n", "<leader>gw", _1_, {desc = "Switch worktree"})
local function _2_()
  local worktree = require("config.worktree")
  return worktree.pick("Find files in worktree", worktree["find-files"])
end
map("n", "<leader>fw", _2_, {desc = "Find files (other worktree)"})
local function _3_()
  local agents = require("config.agents")
  local worktree = require("config.worktree")
  return agents.pick("Go to agent", worktree.switch)
end
map("n", "<leader>ga", _3_, {desc = "Go to agent"})
local function _4_()
  local agents = require("config.agents")
  local worktree = require("config.worktree")
  return agents.pick("Find files in agent", worktree["find-files"])
end
map("n", "<leader>fa", _4_, {desc = "Find files (agent)"})
local function selected_lines()
  local cursor = vim.fn.line(".")
  local anchor = vim.fn.line("v")
  return {math.min(cursor, anchor), math.max(cursor, anchor)}
end
local function map_hunk(key, action, desc)
  local function _5_()
    return require("gitsigns")[action]()
  end
  map("n", key, _5_, {desc = desc})
  local function _6_()
    return require("gitsigns")[action](selected_lines())
  end
  return map("x", key, _6_, {desc = (desc .. " (selection)")})
end
map_hunk("<leader>hs", "stage_hunk", "Stage hunk")
map_hunk("<leader>hr", "reset_hunk", "Reset hunk")
local function _7_()
  local gitsigns = require("gitsigns")
  return gitsigns.preview_hunk()
end
map("n", "<leader>hp", _7_, {desc = "Preview hunk"})
local function _8_()
  local gitsigns = require("gitsigns")
  local on_3f = gitsigns.toggle_deleted()
  return gitsigns.toggle_word_diff(on_3f)
end
return map("n", "<leader>ho", _8_, {desc = "Toggle diff overlay"})
