-- plugins/lsp/mason.lua
-- TODO: Update packages regularly? Reminder?

local M = {
    "williamboman/mason.nvim",
    dependencies = {
        "williamboman/mason-lspconfig.nvim",
        "neovim/nvim-lspconfig",
    },
}

function M.setup()
    require("mason").setup()

    require("mason-lspconfig").setup({
        automatic_installation = true,
    })
end

return M
