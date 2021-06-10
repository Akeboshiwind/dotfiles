-- config/theme/moonlight.lua

local g = vim.g


-- >> Init theme

require('config.theme.init').init()



-- >> Config

g.moonlight_italic_comments = true
g.moonlight_italic_keywords = true
g.moonlight_italic_functions = false
g.moonlight_italic_variables = false
g.moonlight_contrast = true
g.moonlight_borders = true
g.moonlight_disable_background = false

require('moonlight').set()
