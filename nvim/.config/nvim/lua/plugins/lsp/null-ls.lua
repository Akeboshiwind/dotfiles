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
}

M.stylua_cfg = vim.fn.stdpath("config") .. "/config/stylua.toml"
M.cspell_cfg = vim.fn.stdpath("config") .. "/config/cspell.json"

function M.install_tools()
    local mr = require("mason-registry")
    for _, tool in ipairs(M.tools) do
        local p = mr.get_package(tool)
        if not p:is_installed() then
            p:install()
        end
    end
end

function M.read_json_file(filename)
    local f = io.open(filename, "rb")
    if f then
        local content = f:read("*all")
        f:close()
        local t = vim.fn.json_decode(content)
        return t
    end
end

function M.write_json_file(filename, content)
    local f = io.open(filename, "w")
    if f then
        f:write(vim.fn.json_encode(content))
        f:close()
    end
end

function M.cspell_add_exception(word)
    local cfg = M.read_json_file(M.cspell_cfg)
    if cfg and cfg.words then
        table.insert(cfg.words, word)
        M.write_json_file(M.cspell_cfg, cfg)
    end
end

function M.setup_cspell()
    vim.api.nvim_create_user_command("CspellAddException", function(opts)
        M.cspell_add_exception(opts.args)
    end, { nargs = 1 })

    local wk = require("which-key")
    wk.register({
        a = {
            ":CspellAddException <C-r><C-w>",
            "Cspell Add Exception",
        },
    }, { prefix = "<leader>" })
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
                vim.lsp.buf.format({ bufnr = bufnr })
            end,
        })
    end
end

function M.config()
    local null_ls = require("null-ls")
    local sources = require("plugins.lsp.null-ls.sources")

    M.install_tools()

    null_ls.setup({
        on_attach = M.on_attach,
        sources = {
            null_ls.builtins.formatting.terraform_fmt,
            null_ls.builtins.formatting.stylua.with({
                extra_args = { "--config-path", M.stylua_cfg },
            }),
            null_ls.builtins.diagnostics.cspell.with({
                extra_args = { "--config", M.cspell_cfg },
            }),
        },
    })

    null_ls.register(sources.config_file_lints)

    M.setup_cspell()
end

return M
