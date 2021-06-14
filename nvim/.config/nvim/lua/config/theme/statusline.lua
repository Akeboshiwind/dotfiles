-- config/theme/statusline.lua

local opt = vim.opt
local fn = vim.fn


-- >> Utils

-- Given a path, shorten it by taking substrings of each of the path segments
--
-- The file name isn't shortened.
-- Relative paths don't have a `/` at the start
--
-- For example:
-- /my/test/path/to/file.txt => /m/t/p/t/file.txt
-- relative/path/to/file.txt => r/p/t/file.txt
--
-- @param string   path - Path to shorten
-- @param number   n    - Max length of each path segment
-- @return string       - Shortened path
function shorten_path(path, n)
    -- If the path is empty or doesn't look like a path, return early
    if path == "" then
        return ""
    elseif string.find(path, '/') == nil then
        return path
    end

    -- This includes an empty string if we have an absolute path
    -- e.g.
    -- a/b  => { 'a', 'b' }
    -- /a/b => { '', 'a', 'b' }
    local parts = vim.split(path, '/')

    -- Shorten parent folders to be `n` characters
    -- Keep the filename the same length
    local n = n or 1
    -- We know at this point that #parts will be at least 2
    for idx = 1, (#parts - 1) do
        parts[idx] = string.sub(parts[idx], 1, n)
    end

    -- When we have an absolute path this will add the extra `/` to the start
    -- e.g.
    -- { 'a', 'b' }     => 'a/b'
    -- { '', 'a', 'b' } => '/a/b'
    return table.concat(parts, '/')
end

-- Get the shortened path for the cwd
--
-- Unnamed buffers get the name `[unnamed]`
--
-- @return string - Shortened current working path
function statusline_cwd()
    local relative_path = fn.expand('%')

    if relative_path == "" then
        -- We're in an unnamed buffer, so just default the file name
        return "[unnamed]"
    else
        return shorten_path(relative_path)
    end
end



-- >> LSP Config

-- Return a string with a list of diagnostic information
--
-- @return string
function lsp_diagnostics()
    local lsp_status = require('lsp-status')

    local status = {
        lsp_status.status_errors(),
        lsp_status.status_warnings(),
        lsp_status.status_info(),
        lsp_status.status_hints(),
    }

    status = vim.tbl_filter(function(elem) return elem ~= nil end, status)

    return table.concat(status, " ")
end



-- >> Configure the statusline
-- See `:help statusline` for more info on the codes here

-- Clear previous
opt.statusline = ""

-- Add shortened path
opt.statusline = opt.statusline + [[%{luaeval("statusline_cwd()")}]]

-- Add lsp progress
opt.statusline = opt.statusline
    + [[ %{luaeval("require('lsp-status').status_progress()")}]]

-- Separate the start and the end
opt.statusline = opt.statusline + '%='

-- Add lsp diagnostics
opt.statusline = opt.statusline
    + [[ %{luaeval("lsp_diagnostics()")}]]

-- Line number and file length & column number
opt.statusline = opt.statusline + ' %l/%L:%c'

-- Padding at the end
opt.statusline = opt.statusline + ' '
