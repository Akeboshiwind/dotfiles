-- plugins/lsp/null-ls.lua

local M = {
    {
        "jose-elias-alvarez/null-ls.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "williamboman/mason.nvim",
        },
    },
    {
        "williamboman/mason.nvim",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed or {}, {
                "stylua",
                -- "clj-kondo",
            })
        end
    }
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

function M.config(_, opts)
    local null_ls = require("null-ls")
    local sources = require("config.lsp.null-ls.sources")
    local lsputils = require("config.lsp.utils")

    local stylua_cfg = vim.fn.stdpath("config") .. "/config/stylua.toml"
    local commitlint_cfg = vim.fn.stdpath("config") .. "/config/commitlint.config.js"

    null_ls.setup(lsputils.smart_merge_configs(lsputils.default_config, {
        on_attach = M.on_attach,
        sources = {
            null_ls.builtins.formatting.terraform_fmt,
            null_ls.builtins.formatting.stylua.with({
                extra_args = { "--config-path", stylua_cfg },
            }),
            null_ls.builtins.diagnostics.commitlint.with({
                env = {
                    NODE_PATH = vim.fn.stdpath("data") .. "/mason/packages/commitlint/node_modules",
                },
                extra_args = { "--config", commitlint_cfg },
            }),
            -- null_ls.builtins.diagnostics.clj_kondo,
        },
    }))

    null_ls.register(sources.config_file_lints)
end

return M
