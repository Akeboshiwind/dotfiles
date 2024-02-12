-- plugins/telescope.lua

return {
    {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
    },
    {
        "folke/which-key.nvim",
        opts = {
            defaults = {
                ["<leader>f"] = { name = "find" },
                ["<leader>s"] = { name = "search" },
                ["<leader>d"] = { name = "diagnostic" },
                ["<leader>G"] = { name = "git" },
            },
        },
    },
    {
        "nvim-telescope/telescope.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "kyazdani42/nvim-web-devicons",
            "nvim-telescope/telescope-fzf-native.nvim",
            "nvim-telescope/telescope-ui-select.nvim",
            "nvim-telescope/telescope-file-browser.nvim",
            "xiyaowong/telescope-emoji.nvim",
        },
        cmd = "Telescope",
        keys = {
            -- >> find
            {
                "<leader>ff",
                function()
                    require("telescope.builtin").find_files({
                        find_command = {
                            "rg",
                            -- Show hidden files
                            "--hidden",
                            -- -- Ignore any .git directories
                            "--glob",
                            "!**/.git/**",
                            "--files",
                        },
                    })
                end,
                desc = "Browse local files (inc hidden)",
            },
            {
                "<leader>f.",
                function()
                    require("telescope.builtin").git_files({
                        cwd = "~/dotfiles",
                    })
                end,
                desc = "Dotfiles",
            },
            {
                "<leader>fr",
                function()
                    -- % get's the current buffer's path
                    -- :h get's the full path
                    local buffer_relative_path = vim.call("expand", "%:h")
                    require("telescope").extensions.file_browser.file_browser({
                        cwd = buffer_relative_path,
                    })
                end,
                desc = "Browse relative to buffer",
            },
            {
                "<leader>fb",
                function()
                    require("telescope.builtin").buffers({
                        sort_lastused = true,
                    })
                end,
                desc = "Buffers",
            },
            { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Help tags" },
            { "<leader>fy", "<cmd>Telescope filetypes<CR>", desc = "File types" },
            { "<leader>fc", "<cmd>Telescope colorscheme<CR>", desc = "Colorschemes" },
            { "<leader>fm", "<cmd>Telescope keymaps<CR>", desc = "Mappings" },
            { "<leader>fM", "<cmd>Telescope man_pages<CR>", desc = "Man Pages" },
            { "<leader>fB", "<cmd>Telescope builtin<CR>", desc = "Builtins" },

            -- >> search
            { "<leader>ss", "<cmd>Telescope live_grep<CR>", desc = "Search project file contents" },
            {
                "<leader>sr",
                function()
                    -- % get's the current buffer's path
                    -- :h get's the full path
                    local buffer_relative_path = vim.call("expand", "%:h")
                    require("telescope.builtin").live_grep({
                        cwd = buffer_relative_path,
                    })
                end,
                desc = "Search relative to buffer",
            },
            {
                "<leader>st",
                function()
                    require("telescope.builtin").grep_string({
                        search = "TODO",
                    })
                end,
                desc = "Search for TODOs",
            },
            { "<leader>s*", "<cmd>Telescope grep_string<CR>", desc = "Search for word under cursor" },
            { "<leader>s/", "<cmd>Telescope current_buffer_fuzzy_find<CR>", desc = "Fuzzy find in the current buffer" },

            {
                "<leader>se",
                function()
                    require("telescope").extensions.emoji.emoji()
                end,
                desc = "Emoji",
            },

            -- >> diagnostic
            { "<leader>dd", "<cmd>Telescope diagnostics", desc = "List all diagnostics" },
            {
                "<leader>db",
                function()
                    require("telescope.builtin").diagnostics({
                        bufnr = 0,
                    })
                end,
                desc = "List buffer diagnostics",
            },
            {
                "<leader>dn",
                function()
                    vim.diagnostic.goto_next({ float = { border = "rounded" } })
                end,
                desc = "Next",
            },
            {
                "<leader>dp",
                function()
                    vim.diagnostic.goto_prev({ float = { border = "rounded" } })
                end,
                desc = "Previous",
            },

            -- git
            { "<leader>Gb", "<cmd>Telescope git_branches", desc = "Branches" },
        },
        opts = {
            defaults = {
                mappings = {
                    i = {
                        -- Normally when you press <esc> it puts you in normal mode in
                        -- telescope. This binding skips that to just exit.
                        ["<esc>"] = function(...)
                            require("telescope.actions").close(...)
                        end,

                        -- Add easier movement keys
                        ["<C-j>"] = function(...)
                            require("telescope.actions").move_selection_next(...)
                        end,
                        ["<C-k>"] = function(...)
                            require("telescope.actions").move_selection_previous(...)
                        end,

                        -- Show the mappings for the current picker
                        ["<C-h>"] = function(...)
                            require("telescope.actions").which_key(...)
                        end,
                    },
                },
            },
            extensions = {
                fzf = {},
                ["ui-select"] = {},
                emoji = {
                    action = function(emoji)
                        -- Insert the selected emoji after the cursor
                        vim.api.nvim_put({ emoji.value }, "c", false, true)
                    end,
                },
                file_browser = {
                    mappings = {
                        i = {
                            ["<C-c>"] = function(...)
                                require("telescope._extensions.file_browser.actions").create_from_prompt(...)
                            end,
                        },
                    },
                },
            },
        },
        config = function(_, opts)
            local telescope = require("telescope")

            -- >> Setup telescope

            telescope.setup(opts)

            -- >> Add Telescope Extensions

            for extension, _cfg in pairs(opts.extensions) do
                telescope.load_extension(extension)
            end
        end,
    },
}
