-- config/rust-tools.lua

local lsputils = require('utils.lsp')


-- >> Setup

require('rust-tools').setup {
    server = lsputils.smart_merge_configs(
        lsputils.default_config,
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
        }
    ),
}
