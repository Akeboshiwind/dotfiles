-- plugins/lsp/null-ls.lua

local M = {
    "jose-elias-alvarez/null-ls.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "williamboman/mason.nvim",
    },
}

M.tools = {
    "stylua",
    "cspell",
    "commitlint",
    "clj-kondo",
}

function M.on_attach(client, bufnr)
    local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
    if client.supports_method("textDocument/formatting") then
        vim.api.nvim_clear_autocmds({
            group = augroup,
            buffer = bufnr,
        })
        vim.api.nvim_create_autocmd("BufWritePre", {
            group = augroup,
            buffer = bufnr,
            callback = function()
                vim.lsp.buf.format({ bufnr = bufnr })
            end,
        })
    end
end

function M.config()
    local null_ls = require("null-ls")
    local sources = require("config.lsp.null-ls.sources")
    local lsputils = require("config.lsp.utils")

    local mason_utils = require("config.mason.utils")
    mason_utils.install_tools(M.tools)

    local stylua_cfg = vim.fn.stdpath("config") .. "/config/stylua.toml"
    local cspell_cfg = vim.fn.stdpath("config") .. "/config/cspell.json"
    local commitlint_cfg = vim.fn.stdpath("config") .. "/config/commitlint.config.js"

    null_ls.setup(lsputils.smart_merge_configs(lsputils.default_config, {
        on_attach = M.on_attach,
        sources = {
            null_ls.builtins.formatting.terraform_fmt,
            null_ls.builtins.formatting.stylua.with({
                extra_args = { "--config-path", stylua_cfg },
            }),
            null_ls.builtins.diagnostics.cspell.with({
                extra_args = { "--config", cspell_cfg },
            }),
            null_ls.builtins.code_actions.cspell.with({
                config = {
                    create_config_file = false,
                    find_json = function(_)
                        return cspell_cfg
                    end,
                },
            }),
            null_ls.builtins.diagnostics.commitlint.with({
                env = {
                    NODE_PATH = vim.fn.stdpath("data") .. "/mason/packages/commitlint/node_modules",
                },
                extra_args = { "--config", commitlint_cfg },
            }),
            null_ls.builtins.diagnostics.clj_kondo,
        },
    }))

    null_ls.register(sources.config_file_lints)
end

return M
