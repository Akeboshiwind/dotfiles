-- plugins/lsp/lsp-status.lua

local M = {
    'nvim-lua/lsp-status.nvim',
}

function M.config()
    local lsp_status = require('lsp-status')
    local statusline = require('config.theme.statusline')


    -- >> Config

    lsp_status.config {
        indicator_errors = '',
        indicator_warnings = '',
        indicator_info = '',
        indicator_hint = '',
        indicator_ok = '✔',
        indicator_separator = ':',
    }



    -- >> Setup

    lsp_status.register_progress()
    statusline.setup()
end

return M
