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
}

function M.install_tools()
    local mr = require("mason-registry")
    for _, tool in ipairs(M.tools) do
        local p = mr.get_package(tool)
        if not p:is_installed() then
            p:install()
        end
    end
end

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
                if vim.lsp.buf.format then
                    vim.lsp.buf.format({ bufnr = bufnr })
                else
                    vim.lsp.buf.formatting_sync()
                end
            end,
        })
    end
end

function M.config()
    local null_ls = require("null-ls")

    M.install_tools()

    null_ls.setup({
        on_attach = M.on_attach,
        sources = {
            null_ls.builtins.completion.spell,
            null_ls.builtins.formatting.terraform_fmt,
            null_ls.builtins.formatting.stylua.with({
                extra_args = { "--config-path", vim.fn.stdpath("config") .. "config/stylua/stylua.toml" },
            }),
        },
    })
end

return M
