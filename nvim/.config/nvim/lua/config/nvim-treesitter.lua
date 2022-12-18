-- config/nvim-treesitter.lua


-- >> Setup

require('nvim-treesitter.configs').setup {
    ensure_installed = { "comment", "regex" },
    auto_install = true,

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
