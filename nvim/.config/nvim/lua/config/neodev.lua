-- config/neodev.lua

local lsputils = require('utils.lsp')


-- >> Setup

require("neodev").setup {
    library = {
        plugins = {
            "telescope.nvim"
        }
    }
}

require('lspconfig').sumneko_lua.setup {
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