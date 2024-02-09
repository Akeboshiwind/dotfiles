-- plugins/ui.lua
local util = require("util")

return {
    {
        "rcarriga/nvim-notify",
        init = function()
            util.on_very_lazy(function()
                vim.notify = require("notify")
            end)
        end,
        opts = {
            timeout = 3000,
            -- Ensure notifications are always on top
            on_open = function(win)
                vim.api.nvim_win_set_config(win, { zindex = 100 })
            end,
            -- Ensure a reasonable max size
            max_height = function()
                return math.floor(vim.o.lines * 0.75)
            end,
            max_width = function()
                return math.floor(vim.o.columns * 0.75)
            end,
        },
    }
}
