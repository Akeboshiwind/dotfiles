-- config/lua-dev.lua

local lsputils = require('utils.lsp')


-- >> Setup

local luadev = require("lua-dev").setup {
    lspconfig = lsputils.smart_merge_configs(
        lsputils.default_config,
        {
            settings = {
                Lua = {
                    hint = { enable = true },
                },
            },
        }
    )
}

require('lspconfig').sumneko_lua.setup(luadev)
