-- plugins/lang/lua.lua

return {
    {
        "williamboman/mason.nvim",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, {
                "stylua",
            })
        end,
    },
    {
        "stevearc/conform.nvim",
        opts = {
            formatters_by_ft = {
                lua = { "stylua" },
            },
            formatters = {
                stylua = {
                    prepend_args = {
                        "--config-path",
                        vim.fn.stdpath("config") .. "/config/stylua.toml",
                    },
                },
            },
        },
    },
}
