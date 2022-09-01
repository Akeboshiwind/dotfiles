-- config/which-key.lua

local wk = require("which-key")
local tnav = require('nvim-tmux-navigation')


-- >> Setup

tnav.setup {
}



-- >> Mappings

wk.register({
    ["<C-h>"] = { tnav.NvimTmuxNavigateLeft, "Navigate Left" },
    ["<C-j>"] = { tnav.NvimTmuxNavigateDown, "Navigate Left" },
    ["<C-k>"] = { tnav.NvimTmuxNavigateUp, "Navigate Left" },
    ["<C-l>"] = { tnav.NvimTmuxNavigateRight, "Navigate Left" },
}, { mode = 'n' })
