-- plugins/nvim-tmux-navigation.lua
-- Seamless navigation between tmux panes and vim splits

local M = {
    "alexghergh/nvim-tmux-navigation",
}

function M.config()
    local wk = require("which-key")
    local tnav = require("nvim-tmux-navigation")

    -- >> Setup

    tnav.setup({})

    -- >> Mappings

    wk.register({
        ["<C-h>"] = { tnav.NvimTmuxNavigateLeft, "Navigate Left" },
        ["<C-j>"] = { tnav.NvimTmuxNavigateDown, "Navigate Left" },
        ["<C-k>"] = { tnav.NvimTmuxNavigateUp, "Navigate Left" },
        ["<C-l>"] = { tnav.NvimTmuxNavigateRight, "Navigate Left" },
    }, { mode = "n" })
end

return M
