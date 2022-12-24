-- config/which-key.lua

local M = {
    'folke/which-key.nvim',
}

function M.config()

    local opt = vim.opt
    local wk = require("which-key")


    -- >> Configure

    -- leader mapped in init.lua
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
            x = { "<cmd>luafile %<CR>", "Source lua buffer" },
            X = { "<cmd>source %<CR>", "Source vim buffer" },
            w = {
                name = "window",
                ["="] = { "<cmd>wincmd =<CR>", "Equalise all windows" },
                ["+"] = { "<cmd>wincmd +<CR>", "Increase window height" },
                ["-"] = { "<cmd>wincmd -<CR>", "Decrease window height" },
                [">"] = { "<cmd>wincmd <<CR>", "Increase window width" },
                ["<"] = { "<cmd>wincmd ><CR>", "Decrease window width" },
            },
        },
        ["<C-Space>"] = { "<cmd>:WhichKey ''<CR>", "Show base commands" },
    }
end

return M
