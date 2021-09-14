-- config/nvim-treesitter.lua


-- >> Setup

require('nvim-treesitter.configs').setup {
    -- TODO: Just install all maintained?
    ensure_installed = {
        -- languages
        "clojure", "bash", "fennel", "java", "javascript", "lua", "python",
        "rust", "typescript", "vim",

        -- Filetypes
        "html", "css", "dockerfile", "json", "latex", "query", "toml", "yaml",

        -- Other
        "comment", "regex",
    },
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
