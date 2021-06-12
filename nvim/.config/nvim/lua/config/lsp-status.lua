-- config/lsp-status.lua

local lsp_status = require('lsp-status')


-- >> Config

-- TODO: Not sure if these are needed
lsp_status.config {
    indicator_errors = 'E',
    indicator_warnings = 'W',
    indicator_info = 'i',
    indicator_hint = '?',
    indicator_ok = 'Ok',
    indicator_separator = ':',
}



-- >> Setup

lsp_status.register_progress()
