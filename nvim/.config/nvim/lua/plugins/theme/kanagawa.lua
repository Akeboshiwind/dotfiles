-- plugins/theme/kanagawa.lua


local M = {
    "rebelot/kanagawa.nvim",
    enable = true,
}

function M.config()
    require('kanagawa').setup({
        dimInactive = true,        -- dim inactive window `:h hl-NormalNC`
    })

    vim.cmd [[colorscheme kanagawa]]
end

return M
