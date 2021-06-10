-- config/conjure.lua


-- >> Config

local g = vim.g

g["conjure#mapping#prefix"] = "<leader>"

-- Breifly highlight evaluated forms
g["conjure#highlight#enabled"] = true

-- Only enable for clojure (so far anyway)
g["conjure#filetypes"] = { "clojure" }



-- >> Document Mappings
-- TODO: This 😛
