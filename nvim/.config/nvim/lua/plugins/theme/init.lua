-- plugins/theme/init.lua

return {
    { "joshdick/onedark.vim", enabled = false },
    { dir = "~/prog/prog/assorted/solarized.nvim", enabled = false },
    require("plugins.theme.kanagawa"),
    require("plugins.theme.moonlight"),
    require("plugins.theme.tokyonight"),
    require("plugins.theme.vim-solarized8"),
}
