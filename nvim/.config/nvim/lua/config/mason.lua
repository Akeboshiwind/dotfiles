-- config/mason.lua

local mason = require("mason")
local mason_lspconfig = require("mason-lspconfig")


-- >> Setup

mason.setup()

mason_lspconfig.setup({
    automatic_installation = true,
})
