-- plugins/lang/conjure.lua
-- TODO: Move conjure stuff to it's own file?

return {
    {
        "neovim/nvim-lspconfig",
        opts = {
            servers = {
                clojure_lsp = {
                    init_options = {
                        ["cljfmt-config-path"] = vim.fn.stdpath("config") .. "/config/.cljfmt.edn",
                    },
                },
            },
        },
    },
    {
        "PaterJason/cmp-conjure",
        dependencies = {
            "hrsh7th/nvim-cmp",
        },
    },
    {
        "eraserhd/parinfer-rust",
        build = "cargo build --release",
    },
    {
        "folke/which-key.nvim",
        opts = {
            -- TODO: These don't work, why?
            defaults = {
                ["<leader>l"] = { name = "log" },
                ["<leader>e"] = { name = "eval" },
                ["<leader>c"] = { name = "display as comment" },
                ["<leader>g"] = { name = "goto" },

                -- Clojure nrepl specific
                ["<leader>G"] = { name = "git" },
                ["<leader>v"] = { name = "view" },
                ["<leader>s"] = { name = "session" },
                ["<leader>t"] = { name = "test" },
                ["<leader>r"] = { name = "refresh" },
            },
        },
    },
    {
        "Olical/conjure",
        tag = "v4.50.0",
        dependencies = {
            "nvim-telescope/telescope.nvim",
            --"gpanders/nvim-parinfer",
            "eraserhd/parinfer-rust",
            "PaterJason/cmp-conjure",
        },
        init = function()
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
        end,
        config = function()
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
                e = {
                    g = {
                        ":ConjureEval (user/go!)<CR>",
                        "user/go!",
                    },
                    s = {
                        function()
                            -- Save buffer
                            vim.cmd("w")

                            -- clerk/show!
                            local filename = vim.fn.expand("%:p")
                            vim.cmd(string.format('ConjureEval (nextjournal.clerk/show! "%s")', filename))
                        end,
                        "clerk/show!",
                    },
                },
                s = {
                    S = { shadow_select, "Conjure Select Shadowcljs Environment" },
                },
            }, { prefix = "<leader>" })
        end,
    },
}
