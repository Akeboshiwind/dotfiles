-- plugins/theme/kanagawa.lua

local M = {
    "rebelot/kanagawa.nvim",
    enable = true,
    lazy = false,
    priority = 1000,
}

function M.config()
    require("kanagawa").setup({
        dimInactive = true, -- dim inactive window `:h hl-NormalNC`
    })

    vim.cmd([[colorscheme kanagawa]])
end

return M
