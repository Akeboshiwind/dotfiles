-- plugins/lang/typescript-tools.lua

local M = {
    {
        "pmizio/typescript-tools.nvim",
        ft = {
            "javascript",
            "javascriptreact",
            "typescript",
            "typescriptreact",
        },
        dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
        opts = {},
    },
}

return M
