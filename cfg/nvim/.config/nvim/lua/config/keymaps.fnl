(local map vim.keymap.set)

(map :i :fd :<ESC> { :desc "Quick Escape"})
(map :n :<leader>fy "<cmd>Telescope filetypes<cr>" { :desc "Set filetype"})
