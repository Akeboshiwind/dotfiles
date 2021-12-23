-- config/theme/init.lua

local theme = {}

local cmd = vim.cmd
local fn = vim.fn
local opt = vim.opt



-- >> Init function
-- TODO: Don't use init function?
-- TODO: Move stuff here to /init.lua and remove this all together?

function theme.init()
    -- >> Theme

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



    -- >> Appearance

    -- NOTE: These will only work in VTE compatible terminals (urxvt, st, etc.)
    --cmd [[let &t_SI = "\<Esc>[6 q"]]   -- IBeam shape in insert mode
    --cmd [[let &t_SR = "\<Esc>[4 q"]]   -- Underline shape in replace mode
    --cmd [[let &t_EI = "\<Esc>[2 q"]]   -- Block shape in normal mode
end

return theme
