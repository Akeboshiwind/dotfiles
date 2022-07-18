-- config/python-tools.lua

local lspconfig = require('lspconfig')
local lsputils = require('utils.lsp')


-- >> Setup

lspconfig.pylsp.setup(
    lsputils.smart_merge_configs(
        lsputils.default_config,
        {
            on_attach = function(_, _)
                -- >> Install plugins

                -- TODO: Only on first install?
                vim.cmd [[ :PylspInstall python-lsp-black pylsp-rope ]]

                -- >> Format on save

                vim.cmd [[ autocmd BufWritePre *.py lua vim.lsp.buf.formatting_sync(nil, 1000) ]]
            end,
        }
    )
)
