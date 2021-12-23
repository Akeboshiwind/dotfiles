-- config/lsp-status.lua

local lsp_status = require('lsp-status')


-- >> Config

-- TODO: Not sure if these are needed
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
