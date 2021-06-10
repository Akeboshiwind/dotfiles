-- config/nvim-treesitter.lua


-- >> Setup

require('nvim-treesitter.configs').setup {
    -- TODO: Only enable languages we use?
    ensure_installed = "maintained",
    highlight = {
        enable = true,
    },
    indent = {
        enable = false,
    },

    playground = {
        enable = true,
    },

    query_linter = {
        enable = true,
        use_virtual_text = true,
        lint_events = {"BufWrite", "CursorHold"},
    },
}
