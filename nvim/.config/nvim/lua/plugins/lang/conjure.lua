-- plugins/lang/conjure.lua

local M = {
    "Olical/conjure",
    tag = "v4.44.2",
    dependencies = {
        "nvim-telescope/telescope.nvim",
        --"gpanders/nvim-parinfer",
        {
            "eraserhd/parinfer-rust",
            build = "cargo build --release",
        },
        {
            "PaterJason/cmp-conjure",
            dependencies = {
                "hrsh7th/nvim-cmp",
                "Olical/conjure",
            },
        },
    },
}

function M.config()
    local g = vim.g

    g["conjure#mapping#prefix"] = "<leader>"

    -- Briefly highlight evaluated forms
    g["conjure#highlight#enabled"] = true

    -- Only enable for clojure (so far anyway)
    g["conjure#filetypes"] = { "clojure" }

    -- Disable the mapping for selecting a session as that collides with searching
    -- files within a project
    g["conjure#client#clojure#nrepl#mapping#session_select"] = false

    -- Disable auto-starting a babashka repl
    g["conjure#client#clojure#nrepl#connection#auto_repl#enabled"] = false

    -- >> Custom commands

    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    local shadow_select = function(opts)
        opts = opts or {}

        -- A set used to de-duplicate the entries
        -- To use a table as a set, use the keys as values
        -- # Insertion:
        -- set[value] = true
        -- # Contains?
        -- if set[value] then print("contains") end
        -- See: https://www.lua.org/pil/11.5.html
        local entry_cache = {}

        -- Does three things to the `ps aux` output:
        --  - Filters for shadow-cljs watch commands
        --  - Returns the app name
        --  - De-duplicates the results
        opts.entry_maker = function(entry)
            -- NOTE: Have to put the `-` in a set for some reason...
            local app = entry:match("shadow[-]cljs watch (%w*)")

            -- Skip entries that don't match
            if not app then
                return nil
            end

            -- Cache the entry
            if entry_cache[app] then
                return nil
            end
            entry_cache[app] = true

            -- Return the app
            return {
                value = app,
                display = app,
                ordinal = app,
            }
        end

        pickers
            .new(opts, {
                prompt_title = "shadow-cljs apps",
                finder = finders.new_oneshot_job({ "ps", "aux" }, opts),
                sorter = conf.generic_sorter(opts),
                attach_mappings = function(prompt_bufnr, _)
                    -- When an app is selected, run ConjureShadowSelect
                    actions.select_default:replace(function()
                        actions.close(prompt_bufnr)
                        local selection = action_state.get_selected_entry()
                        local app = selection.value

                        vim.cmd(string.format("ConjureShadowSelect %s", app))
                    end)
                    return true
                end,
            })
            :find()
    end

    -- >> Document Mappings

    local wk = require("which-key")

    -- Base Conjure Mappings
    wk.register({
        l = {
            name = "log",
            s = "Open in new horizontal split window",
            v = "Open in new vertical split window",
            t = "Open in new tab",
            q = "Close all visible windows in current tab",
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
            g = {
                ":ConjureEval (user/go!)<CR>",
                "user/go!",
            },
        },
        g = {
            name = "goto",
            d = "Definition",
        },
    }, { prefix = "<leader>" })

    wk.register({
        E = "Evaluate selection",
    }, { prefix = "<leader>", mode = "v" })

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
            S = { shadow_select, "Conjure Select Shadowcljs Environment" },
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
    }, { prefix = "<leader>" })
end

return M
