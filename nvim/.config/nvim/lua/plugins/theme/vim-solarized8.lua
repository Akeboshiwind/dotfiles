-- plugins/theme/vim-solarized8.lua

local M = {
    "lifepillar/vim-solarized8",
    enabled = false,
}

function M.config()
    vim.opt.background = "dark"
    vim.cmd([[colorscheme solarized8_high]])
end

return M
