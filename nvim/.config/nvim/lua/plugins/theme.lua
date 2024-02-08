-- plugins/theme.lua

return {
    {
        "rebelot/kanagawa.nvim",
        enable = true,
        priority = 1000, -- Load early
        config = function()
            require("kanagawa").setup({
                -- dim inactive window `:h hl-NormalNC`
                dimInactive = true,
            })

            vim.cmd([[colorscheme kanagawa]])
        end,
    },
}
