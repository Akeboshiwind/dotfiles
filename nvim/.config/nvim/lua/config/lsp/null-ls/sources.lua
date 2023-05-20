-- plugins/lsp/null-ls/sources.lua

local null_ls = require("null-ls")

-- >> Utils

local function starts_with(str, start)
    return str:sub(1, #start) == start
end

local function ends_with(str, ending)
    return ending == "" or str:sub(-#ending) == ending
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
                M.config_dir .. "/.git",
            }
            for _, value in ipairs(prefix_exceptions) do
                if starts_with(params.bufname, value) then
                    return diagnostics
                end
            end

            -- >> Suffix exceptions

            local suffix_exceptions = {
                ".json",
            }
            for _, value in ipairs(suffix_exceptions) do
                if ends_with(params.bufname, value) then
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
                if not ends_with(params.bufname, maybe_title) then
                    table.insert(diagnostics, diagnostic)
                end
            end

            return diagnostics
        end,
    },
}

return M
