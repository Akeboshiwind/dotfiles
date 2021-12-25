-- config/lua-dev.lua
local lsp_installer = require('utils.lsp.installer')
local lsp_config = require('utils.lsp.config')


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
            },
        },
    },
}

server:setup(luadev)
