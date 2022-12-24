-- plugins/lsp/null-ls/sources.lua

local null_ls = require("null-ls")


-- >> Utils

local function starts_with(str, start)
    return string.sub(str, 1, string.len(start)) == start
end

local function escape_str(str)
    return str:gsub("([%(%)%.%%%+%-%*%?%[%^%$%]])", "%%%1")
end

-- >> Module

local M = {}

M.config_dir = vim.fn.expand("~") .. "/dotfiles"

M.config_file_lints = {
    method = null_ls.methods.DIAGNOSTICS,
    condition = function(utils)
        return utils.root_matches(M.config_dir)
    end,
    filetypes = {},
    generator = {
        fn = function(params)
            local diagnostics = {}

            -- >> Prefix exceptions

            local prefix_exceptions = {
                M.config_dir .. "/.git"
            }
            for _, value in ipairs(prefix_exceptions) do
                if starts_with(params.bufname, value) then
                    return diagnostics
                end
            end

            -- >> Config Titles
            -- I expect the first line of config files to end with part of
            -- the path of the file.
            -- So something like:
            -- ```lua
            -- -- my/config/file.lua
            -- ```
            -- There may be some exceptions like files that start with #!
            local first_line = params.content[1]

            local diagnostic = {
                range = {
                    start = { line = 0, character = 0 },
                    ["end"] = { line = 0, character = #first_line },
                },
                severity = vim.lsp.protocol.DiagnosticSeverity.Warning,
                message = "Missing Config Title",
                source = "config-title",
            }

            local maybe_title = string.match(first_line, "(%S+)$")
            if not maybe_title then
                table.insert(diagnostics, diagnostic)
            else
                maybe_title = escape_str(maybe_title)
                local pattern = string.format("%s$", maybe_title)

                if not string.match(params.bufname, pattern) then
                    table.insert(diagnostics, diagnostic)
                end
            end

            return diagnostics
        end,
    },
}

return M
