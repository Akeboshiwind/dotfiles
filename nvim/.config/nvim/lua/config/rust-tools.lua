-- config/rust-tools.lua


-- >> Config

local wk = require("which-key")

require('rust-tools').setup {
    server = {
        on_attach = function()
            _G.lsp.setup_mappings()

            -- TODO: Add mappings for rust-tools specific behavior
            -- TODO: Document any mappings added by rust-tools
            wk.register({
            }, {
                prefix = "<leader>",
                buffer = 0,
            })
        end,
    },
}
