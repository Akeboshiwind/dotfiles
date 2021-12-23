-- config/telescope.lua

local telescope = require('telescope')
local actions = require('telescope.actions')


-- >> Utils

local previewers = require('telescope.previewers')
local previewers_utils = require('telescope.previewers.utils')



-- >> Setup telescope

telescope.setup {
    defaults = {
        mappings = {
            i = {
                -- Normally when you press <esc> it puts you in normal mode in
                -- telescope. This binding skips that to just exit.
                ["<esc>"] = actions.close,

                -- Add easier movement keys
                ["<C-j>"] = actions.move_selection_next,
                ["<C-k>"] = actions.move_selection_previous,
            }
        },
        preview = {
            filesize_hook = function(filepath, bufnr, opts)
                local max_bytes = 100000
                local cmd = {"head", "-c", max_bytes, filepath}
                previewers_utils.job_maker(cmd, bufnr, opts)
            end
        }
    }
}



-- >> Add Telescope Extensions

--telescope.load_extension('fzy_native')
telescope.load_extension('fzf')



-- >> Mappings

local wk = require("which-key")
local builtin = require('telescope.builtin')

wk.register({
    f = {
        name = "find",
        f = { builtin.find_files, "Browse local files"},
        g = { builtin.git_files, "Current repo files"},
        o = { builtin.oldfiles, "Recently opened files"},
        ["."] = { function()
            builtin.git_files({
                cwd = "~/dotfiles",
            })
        end, "Dotfiles"},
        p = { function()
            builtin.find_files({
                cwd = "~/prog/",
            })
        end, "~/prog"},
        P = { function()
            builtin.find_files({
                cwd = "~/.local/share/nvim/plugged/",
            })
        end, "Plugin source files"},
        r = { function()
            -- % get's the current buffer's path
            -- :h get's the full path
            local buffer_relative_path = vim.call("expand", "%:h")
            builtin.file_browser({
                cwd = buffer_relative_path,
            })
        end, "Browse relative to buffer"},

        b = { function()
            builtin.buffers({
                sort_lastused = true,
            })
        end, "Buffers"},
        h = { builtin.help_tags, "Help tags"},
        y = { builtin.filetypes, "File types"},
        c = { builtin.colorscheme, "Colorschemes"},
        m = { builtin.keymaps, "Mappings"},

        B = { builtin.builtin, "Builtins"},
    },
    s = {
        name = "search",
        s = { builtin.live_grep, "Search project file contents"},
        r = { function()
            -- % get's the current buffer's path
            -- :h get's the full path
            local buffer_relative_path = vim.call("expand", "%:h")
            builtin.live_grep({
                cwd = buffer_relative_path,
            })
        end, "Search relative to buffer"},
        ["*"] = { builtin.grep_string, "Search for word under cursor"},
        ["/"] = { builtin.current_buffer_fuzzy_find, "Fuzzy find in the current buffer"},

    },
    G = {
        name = "git",
        g = { ":G<CR>", "Branches"},

        b = { builtin.git_branches, "Branches"},
    },
}, { prefix = "<leader>", })
