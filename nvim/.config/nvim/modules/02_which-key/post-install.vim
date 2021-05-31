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
EOF
