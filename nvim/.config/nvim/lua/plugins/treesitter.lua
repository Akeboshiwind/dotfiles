-- plugins/treesitter.lua

return {
    {
        "nvim-treesitter/nvim-treesitter",
        -- dir = '~/prog/prog/assorted/nvim-treesitter',
        -- branch = '0.5-compat',
        build = ":TSUpdate",
        dependencies = {
            -- {
            --     "nvim-treesitter/playground",
            --     cmd = "TSPlaygroundToggle",
            -- },
        },
        opts = {
            ensure_installed = { "comment", "regex" },
            auto_install = true,

            highlight = {
                enable = true,
            },

            indent = {
                enable = false,
            },

            -- playground = {
            --     enable = true,
            -- },

            query_linter = {
                enable = true,
                use_virtual_text = true,
                lint_events = { "BufWrite", "CursorHold" },
            },
        },
        config = function(_, opts)
            require("nvim-treesitter.configs").setup(opts)
        end,
    },
}
