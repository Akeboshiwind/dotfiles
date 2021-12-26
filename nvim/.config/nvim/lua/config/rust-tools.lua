-- config/rust-tools.lua

local lsp_installer = require('utils.lsp.installer')
local lsp_config = require('utils.lsp.config')


-- >> Install server

local server = lsp_installer.get_server("rust_analyzer")

if not server:is_installed() then
    print("Installing LSP server")
    server:install()
end



-- >> Setup

require('rust-tools').setup {
    server = lsp_config.smart_merge_configs(
        lsp_config.default_config,
        {
            on_attach = function(_, bufnr)
                local wk = require("which-key")

                -- Non-Prefixed
                wk.register({
                    K = { require('rust-tools.hover_actions').hover_actions,
                           "Hover actions" },
                }, {
                    buffer = bufnr,
                })

                -- Leader
                wk.register({
                    g = {
                        c = { require('rust-tools.open_cargo_toml').open_cargo_toml,
                              "Cargo toml file" },
                        p = { require('rust-tools.parent_module').parent_module,
                              "Parent module" },
                    },
                    r = {
                        r = { require('rust-tools.runnables').runnables,
                              "Show Runnables" },
                    },
                    me = { require('rust-tools.expand_macro').expand_macro,
                           "Macroexpand" },
                }, {
                    prefix = "<leader>",
                    buffer = bufnr,
                })
            end,
        },
        {
            settings = {
                ["rust-analyzer"] = {
                    checkOnSave = {
                        command = "clippy"
                    }
                }
            }
        },
        -- TODO: Move this after own defaults?
        server:get_default_options()
    ),
}
