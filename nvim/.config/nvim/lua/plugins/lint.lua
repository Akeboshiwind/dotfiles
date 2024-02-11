-- plugins/lint.lua
local util = require("util")

return {
    {
        "williamboman/mason.nvim",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, {
                "commitlint",
            })
        end,
    },
    {
        "mfussenegger/nvim-lint",
        opts = {
            -- Event to trigger linters
            events = { "BufWritePost", "BufReadPost", "InsertLeave" },
            linters_by_ft = {
                gitcommit = { "commitlint" },
            },
            -- Add new linters or override existing ones
            linters = {
                commitlint = {
                    args = {
                        "--config",
                        vim.fn.stdpath("config") .. "/config/commitlint.config.js",
                        "--extends",
                        vim.fn.stdpath("data")
                            .. "/mason/packages/commitlint/node_modules/@commitlint/config-conventional",
                    },
                },
            },
        },
        config = function(_, opts)
            local lint = require("lint")

            -- Add new linters or override existing ones
            for name, linter in pairs(opts.linters) do
                if type(linter) == "table" and type(lint.linters[name]) == "table" then
                    lint.linters[name] = vim.tbl_deep_extend("force", lint.linters[name], linter)
                else
                    lint.linters[name] = linter
                end
            end

            lint.linters_by_ft = opts.linters_by_ft

            -- Add autocmd to trigger linters
            vim.api.nvim_create_autocmd(opts.events, {
                group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
                callback = util.debounce(100, function()
                    lint.try_lint()
                end),
            })
        end,
    },
}
