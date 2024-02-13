-- plugins/ui.lua
local util = require("util")

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

    {
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
    },

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
    },

    {
        "alexghergh/nvim-tmux-navigation",
        opts = {},
        -- stylua: ignore
        keys = {
            {"<C-h>", function() require("nvim-tmux-navigation").NvimTmuxNavigateLeft() end,  desc="Navigate Left" },
            {"<C-j>", function() require("nvim-tmux-navigation").NvimTmuxNavigateDown() end,  desc="Navigate Left" },
            {"<C-k>", function() require("nvim-tmux-navigation").NvimTmuxNavigateUp() end,    desc="Navigate Left" },
            {"<C-l>", function() require("nvim-tmux-navigation").NvimTmuxNavigateRight() end, desc="Navigate Left" },
        },
    },
}
