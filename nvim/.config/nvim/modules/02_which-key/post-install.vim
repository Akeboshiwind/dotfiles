" post-install.vim


" >> Configure

lua << EOF
local wk = require("which-key")


-- >> Setup
wk.setup {
    triggers_blacklist = {
        -- Ignore escape key 'fd'
        i = { "f" },
    }
}



-- >> Mappings

wk.register({
    x = { "<cmd>source %<CR>", "Source buffer" }
}, { prefix = "<leader>" })

EOF
