-- plugins/lang/python-tools.lua
local util = require("util")

local M = {
    {
        "neovim/nvim-lspconfig",
        opts = {
            servers = {
                pylsp = {
                    on_attach = function(_, _)
                        -- TODO: Move to mason.nvim
                        -- Probably:
                        -- - Add conform.nvim for formatting
                        -- - move black to conform.nvim
                        -- - remove pylsp-rope (I never use it)

                        -- >> Install plugins

                        -- TODO: Only on first install?
                        vim.cmd([[ :PylspInstall python-lsp-black pylsp-rope ]])

                        -- >> Format on save

                        vim.cmd([[ autocmd BufWritePre *.py lua vim.lsp.buf.format(nil, 1000) ]])
                        vim.notify("Run custom on_attach", vim.log.levels.INFO)
                    end
                },
            },
        },
    },
}

return M
