-- plugins/which-key.lua

return {
    {
        "folke/which-key.nvim",
        init = function()
            -- leader mapped in init.lua
            vim.opt.timeoutlen = 400
        end,
        event = "VeryLazy",
        keys = {
            { "fd", "<ESC>", desc = "Quick Escape", mode = "i" },

            { "*", "g*", desc = "Search in buffer for match" },
            { "#", "g#", desc = "Search in buffer for match, backwards" },

            { "<leader>x", "<cmd>luafile %<CR>", desc = "Source lua buffer" },
            { "<leader>X", "<cmd>source %<CR>", desc = "Source vim buffer" },

            { "<leader>w=", "<cmd>wincmd =<CR>", desc = "Equalise all windows" },
            { "<leader>w+", "<cmd>wincmd +<CR>", desc = "Increase window height" },
            { "<leader>w-", "<cmd>wincmd -<CR>", desc = "Decrease window height" },
            { "<leader>w>", "<cmd>wincmd <<CR>", desc = "Increase window width" },
            { "<leader>w<", "<cmd>wincmd ><CR>", desc = "Decrease window width" },

            { "<C-Space>", "<cmd>:WhichKey ''<CR>", desc = "Show base commands" },
        },
        opts = {
            plugins = { spelling = true },
            triggers_blacklist = {
                -- Ignore escape key 'fd'
                i = { "f" },
            },
            defaults = {
                ["<leader>w"] = { name = "window" },
            },
        },
        config = function(_, opts)
            local wk = require("which-key")

            wk.setup(opts)
            wk.register(opts.defaults)
        end,
    },
}
