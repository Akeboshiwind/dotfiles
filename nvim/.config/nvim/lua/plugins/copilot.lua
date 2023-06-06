-- plugins/copilot.lua

local M = {
    "zbirenbaum/copilot.lua",
    event = "VeryLazy",
    dependencies = {
        {
            "zbirenbaum/copilot-cmp",
            config = function()
                require("copilot_cmp").setup()
            end,
        },
    },
    opts = {
        panel = {
            enabled = false,
        },
        suggestion = {
            enabled = false,
        },
    },
}

return M
