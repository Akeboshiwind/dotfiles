-- config/vimspector.lua

local g = vim.g
local fn = vim.fn


-- >> Vimspector config

-- Set the basedir to look for all configs in the right place
g.vimspector_base_dir = fn.expand('$HOME/.config/nvim/config/vimspector/')



-- >> Mappings

local wk = require("which-key")

wk.register({
    D = {
        name = "debug",

        b = { [[:echom "Just setup a breakpoint then run the code"<CR>]],
              "Show Reminder" },

        c = { "<Plug>VimspectorContinue", "Continue" },
        q = { "<Plug>VimspectorStop", "Stop" },
        r = { "<Plug>VimspectorRestart", "Restart" },
        p = { "<Plug>VimspectorPause", "Pause" },
        e = { "<Plug>VimspectorBalloonEval", "Eval Selection" },

        t = {
            name = "toggle",
            b = { "<Plug>VimspectorToggleBreakpoint", "Breakpoint" },
            c = { "<Plug>VimspectorToggleConditionalBreakpoint",
                  "Conditional Breakpoint" },
            a = { "<Plug>VimspectorAddFunctionBreakpoint",
                  "Add Function Breakpoint" },
        },

        s = {
            name = "step",
            r = { "<Plug>VimspectorRunToCursor", "Run to Cursor" },
            i = { "<Plug>VimspectorStepInto", "Into" },
            o = { "<Plug>VimspectorStepOut", "Out" },
            v = { "<Plug>VimspectorStepOver", "Over" },
        },
    },
}, { prefix = "<leader>" })
