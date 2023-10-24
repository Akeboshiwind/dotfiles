-- plugins/lang/python-tools.lua

local M = {
    dir = "~/.config/nvim/local_plugins/python-tools.nvim",
    dependencies = { "mason.nvim" },
}

function M.setup()
    local lsputils = require("config.lsp.utils")

    -- >> Setup

    require("lspconfig").pylsp.setup(lsputils.smart_merge_configs(lsputils.default_config, {
        on_attach = function(_, _)
            -- >> Install plugins

            -- TODO: Only on first install?
            vim.cmd([[ :PylspInstall python-lsp-black pylsp-rope ]])

            -- >> Format on save

            vim.cmd([[ autocmd BufWritePre *.py lua vim.lsp.buf.format(nil, 1000) ]])
            print("Run custom on_attach")
        end,
    }))
end

return M
