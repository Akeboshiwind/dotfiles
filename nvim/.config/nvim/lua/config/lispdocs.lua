-- config/lispdocs.lua


-- >> Config

local g = vim.g

-- Disable lispdocs
g["lispdocs_mappings"] = 0



-- >> Mappings

local wk = require("which-key")
local lispdocs = require'lispdocs'

wk.register({
    f = {
        name = "find",
        d = { lispdocs.find, "TODO" }
    }
}, { prefix = "<leader>", })
