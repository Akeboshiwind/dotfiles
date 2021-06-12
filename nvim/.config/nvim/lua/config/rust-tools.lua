-- config/rust-tools.lua

local lsp_installer = require('config.nvim-lsp-installer')
local lsp_config = require('config.nvim-lspconfig')


-- >> Install server

local server = lsp_installer.get_server("rust_analyzer")

if not server:is_installed() then
    print("Installing LSP server")
    server:install()
end



-- >> Configure

require('rust-tools').setup {
    server = lsp_config.compose_config({
        on_attach = function(_client, bufnr)
            local wk = require("which-key")

            -- TODO: Add mappings for rust-tools specific behavior
            -- TODO: Document any mappings added by rust-tools
            wk.register({
            }, {
                prefix = "<leader>",
                buffer = bufnr,
            })
        end,
    }, server:get_default_options()),
}
