-- [nfnl] lua/config/keymaps.fnl
local map = vim.keymap.set
return map("i", "fd", "<ESC>", {desc = "Quick Escape"})
