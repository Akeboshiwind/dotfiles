-- plugins/theme/tokyonight.lua

local M = {
    "folke/tokyonight.nvim",
    enabled = false,
}

function M.config()
    vim.g.tokyonight_style = "night"
    vim.cmd([[colorscheme tokyonight]])
end

return M
