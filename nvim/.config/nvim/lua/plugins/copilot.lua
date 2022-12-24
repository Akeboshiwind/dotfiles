-- plugins/copilot.lua

local M = {
    "zbirenbaum/copilot.lua",
    event = "VeryLazy",
    dependencies = {
        {
            "zbirenbaum/copilot-cmp",
            config = function ()
                require("copilot_cmp").setup()
            end,
        }
    }
}

function M.config()
    require("copilot").setup({
        panel = {
            enabled = false,
        },
        suggestion = {
            enabled = false,
        },
    })
end

return M
