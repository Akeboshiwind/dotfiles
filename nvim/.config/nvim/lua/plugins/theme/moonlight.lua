-- plugins/theme/moonlight.lua


local M = {
    'shaunsingh/moonlight.nvim',
    enabled = false,
}

function M.config()
    local g = vim.g

    g.moonlight_italic_comments = true
    g.moonlight_italic_keywords = true
    g.moonlight_italic_functions = false
    g.moonlight_italic_variables = false
    g.moonlight_contrast = true
    g.moonlight_borders = true
    g.moonlight_disable_background = false

    require('moonlight').set()
end

return M
