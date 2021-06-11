-- config/rust-tools.lua

local lsp_installer = require('config.nvim-lsp-installer')


-- >> Install server

local server = lsp_installer.get_server("rust_analyzer")

if not server.is_installed() then
    print("Installing LSP server")
    server.install()
end



-- >> Configure

require('rust-tools').setup {
    server = vim.tbl_deep_extend("keep", {
        on_attach = function()
            require('config.nvim-lspconfig').setup_mappings()

            local wk = require("which-key")

            -- TODO: Add mappings for rust-tools specific behavior
            -- TODO: Document any mappings added by rust-tools
            wk.register({
            }, {
                prefix = "<leader>",
                buffer = 0,
            })
        end,
    }, server._default_options),
}
