-- plugins/lualine.lua

local M = {
    "nvim-lualine/lualine.nvim",
    dependencies = {
        "kyazdani42/nvim-web-devicons",
    },
    opts = {
        sections = {
            lualine_a = { "filename" },
            lualine_b = { "branch", "diff", "diagnostics" },
            lualine_c = { "searchcount" },
            lualine_x = {
                {
                    require("lazy.status").updates,
                    cond = require("lazy.status").has_updates,
                    color = { fg = "#ff9e64" },
                },
            },
            lualine_y = {},
            lualine_z = { "location" },
        },
    },
}

return M