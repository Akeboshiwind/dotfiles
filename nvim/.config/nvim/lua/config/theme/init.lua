-- config/theme/init.lua

local theme = {}

local cmd = vim.cmd
local fn = vim.fn
local opt = vim.opt



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
-- @param {string}   path Path to shorten
-- @param {number=1} n    Max length of each path segment
-- @return {string}       Shortened path
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
-- @return {string} Shortened current working path
function statusline_cwd()
    local relative_path = fn.expand('%')

    if relative_path == "" then
        -- We're in an unnamed buffer, so just default the file name
        return "[unnamed]"
    else
        return shorten_path(relative_path)
    end
end



-- >> Init function
-- TODO: Don't use init function?

function theme.init()
    -- >> Theme

    cmd [[syntax enable]]

    -- TODO: Do I need this?
    if fn.exists('+termguicolors') ~= 0 then
        -- Not sure what these bits do tbh
        -- cmd [[&t_8f="\<Esc>[38;2;%lu;%lu;%lum"]]
        -- cmd [[&t_8b="\<Esc>[48;2;%lu;%lu;%lum"]]

        -- Tell nvim that terminal support truecolor
        -- Can test using the truecolor-test script in bin or at:
        -- https://gist.github.com/XVilka/8346728
        opt.termguicolors = true
    end


    -- let g:tokyonight_style = "night"
    -- colorscheme tokyonight



    -- >> Appearance

    -- Highlight matches
    opt.hlsearch = true

    -- NOTE: These will only work in VTE compatible terminals (urxvt, st, etc.)
    --cmd [[let &t_SI = "\<Esc>[6 q"]]   -- IBeam shape in insert mode
    --cmd [[let &t_SR = "\<Esc>[4 q"]]   -- Underline shape in replace mode
    --cmd [[let &t_EI = "\<Esc>[2 q"]]   -- Block shape in normal mode



    -- >> Statusline
    -- See `:help statusline` for more info on the codes here

    opt.statusline = ""
    opt.statusline = opt.statusline + '%{luaeval("statusline_cwd()")}'

    -- Separate the start and the end
    opt.statusline = opt.statusline + '%='

    -- Line number and file length & column number
    opt.statusline = opt.statusline + ' %l/%L:%c'

    -- Padding at the end
    opt.statusline = opt.statusline + ' '
end

return theme
