-- plugins/format.lua

return {
    {
        "stevearc/conform.nvim",
        event = { "BufWritePre" },
        cmd = { "ConformInfo" },
        opts = {
            formatters_by_ft = {},
            format_on_save = function(bufnr)
                local opts = { timeout_ms = 500, lsp_fallback = true }

                if vim.bo[bufnr].filetype == "clojure" then
                    opts.lsp_fallback = false
                end

                return opts
            end,
            formatters = {},
        },
    },
}
