-- config/lua-dev.lua
local lsp_installer = require('config.nvim-lsp-installer')
local lsp_config = require('config.nvim-lspconfig')


-- >> Install server

local server = lsp_installer.get_server("sumneko_lua")

if not server:is_installed() then
    print("Installing LSP server")
    server:install()
end



-- >> Setup

local luadev = require("lua-dev").setup {
    lspconfig = lsp_config.compose_config{
        settings = {
            Lua = {
                hint = { enable = true },
                workspace = {
                    -- For conjure
                    preloadFileSize = 150,
                },
            },
        },
    },
}

server:setup(luadev)
