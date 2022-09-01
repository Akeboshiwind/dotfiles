-- config/mason.lua


-- >> Setup

require("mason").setup()

require("mason-lspconfig").setup({
    automatic_installation = true,
})
