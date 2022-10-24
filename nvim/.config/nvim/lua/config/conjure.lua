-- config/conjure.lua


-- >> Config

local g = vim.g

g["conjure#mapping#prefix"] = "<leader>"

-- Breifly highlight evaluated forms
g["conjure#highlight#enabled"] = true

-- Only enable for clojure (so far anyway)
g["conjure#filetypes"] = { "clojure" }

-- Disable the mapping for selecting a session as that collides with searching
-- files within a project
g["conjure#client#clojure#nrepl#mapping#session_select"] = false


-- >> Document Mappings

local wk = require("which-key")

-- Base Conjure Mappings
wk.register({
    l = {
        name = "log",
        s = "Open in new horizontal split window",
        v = "Open in new vertical split window",
        t = "Open in new tab",
        q = "Close all visibal windows in current tab",
        r = "Soft reset",
        R = "Hard reset",
    },
    E = "Evaluate given motion",
    e = {
        name = "eval",
        e = "Form under the cursor",
        r = "Root form under the cursor",
        w = "Word under the cursor",
        c = {
            name = "display as comment",
            e = "Form under the cursor",
            r = "Root form under the cursor",
            w = "Word under the cursor",
        },
        ["!"] = "Replacing the Form under the cursor",
        m = "Form at the given mark",
        f = "File from disk",
        b = "Current buffer",
    },
    g = {
        name = "goto",
        d = "Definition",
    },
}, { prefix = "<leader>", })

wk.register({
    E = "Evaluate selection",
}, { prefix = "<leader>", mode = 'v' })

-- Clojure Nrepl Client Mappings
wk.register({
    c = {
        name = "connection",
        d = "Disconnect current",
        f = "Connect",
    },
    ei = "Interrupt oldest",
    v = {
        name = "view",
        e = "Last exception",
        ["1"] = "Most recent evaluation",
        ["2"] = "2nd most recent evaluation",
        ["3"] = "3rd most recent evaluation",
        s = "Source of symbol under cursor",
    },
    s = {
        name = "session",
        c = "Clone",
        f = "Create fresh",
        q = "Close current",
        Q = "Close all",
        l = "List",
        n = "Next",
        p = "Previous",
        s = "Prompt to select",
    },
    t = {
        name = "test",
        a = "Run all loaded tests",
        n = "Run tests in namespace",
        N = "Run tests in testing namespace",
        c = "Run under cursor",
    },
    r = {
        name = "refresh",
        r = "Changed namespaces",
        a = "All, even unchanged",
        c = "Clear refresh cache",
    },
}, { prefix = "<leader>", })
