-- config/which-key.lua

local opt = vim.opt
local wk = require("which-key")


-- >> Configure

vim.g.mapleader = ","
opt.timeoutlen = 400



-- >> Setup

wk.setup {
    triggers_blacklist = {
        -- Ignore escape key 'fd'
        i = { "f" },
    }
}



-- >> Mappings

wk.register({
    fd = { "<ESC>", "Quick Escape" }
}, { mode = 'i' })

wk.register {
    ["<leader>"] = {
        x = { "<cmd>source %<CR>", "Source vim buffer" },
        X = { "<cmd>luafile %<CR>", "Source lua buffer" },
    },
    ["<C-Space>"] = { "<cmd>:WhichKey ''<CR>", "Show base commands" },
}


