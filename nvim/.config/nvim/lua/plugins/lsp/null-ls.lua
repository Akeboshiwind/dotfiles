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

local function starts_with(str, start)
    return string.sub(str, 1, string.len(start)) == start
end

local function escape_str(str)
    return str:gsub("([%(%)%.%%%+%-%*%?%[%^%$%]])", "%%%1")
end

function M.config()
    local null_ls = require("null-ls")

    M.install_tools()

    local config_dir = vim.fn.expand("~") .. "/dotfiles"
    local config_file_lints = {
        method = null_ls.methods.DIAGNOSTICS,
        condition = function(utils)
            return utils.root_matches(config_dir)
        end,
        filetypes = {},
        generator = {
            fn = function(params)
                local diagnostics = {}

                -- >> Config Titles
                -- I expect the first line of config files to end with part of
                -- the path of the file.
                -- So something like:
                -- ```lua
                -- -- my/config/file.lua
                -- ```
                -- There may be some exceptions like files that start with #!

                local first_line = params.content[1]
                local maybe_title = string.match(first_line, "(%S+)$")
                maybe_title = escape_str(maybe_title)
                local pattern = string.format("%s$", maybe_title)

                if not string.match(params.bufname, pattern) then
                    local range = {
                        start = { line = 0, character = 0 },
                        ["end"] = { line = 0, character = #first_line },
                    }
                    table.insert(diagnostics, {
                        range = range,
                        severity = vim.lsp.protocol.DiagnosticSeverity.Warning,
                        message = "Missing Config Title",
                        source = "config-title",
                    })
                end

                return diagnostics
            end,
        },
    }

    null_ls.register(config_file_lints)

    null_ls.setup({
        on_attach = M.on_attach,
        sources = {
            null_ls.builtins.formatting.terraform_fmt,
            null_ls.builtins.formatting.stylua.with({
                extra_args = { "--config-path", vim.fn.stdpath("config") .. "config/stylua/stylua.toml" },
            }),
        },
    })
end

return M
