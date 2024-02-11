-- plugins/lang/python-tools.lua
local util = require("util")

local M = {
    {
        "williamboman/mason.nvim",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, {
                "black",
            })
        end,
    },
    {
        "stevearc/conform.nvim",
        opts = {
            formatters_by_ft = {
                python = { "black" },
            },
        },
    },
    {
        "neovim/nvim-lspconfig",
        opts = {
            servers = {
                pylsp = {},
            },
        },
    },
}

return M
