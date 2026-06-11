-- [nfnl] lua/config/keymaps.fnl
local map = vim.keymap.set
map("i", "fd", "<ESC>", {desc = "Quick Escape"})
return map("n", "<leader>fy", "<cmd>Telescope filetypes<cr>", {desc = "Set filetype"})
