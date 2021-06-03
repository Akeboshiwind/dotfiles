" post-install.vim


" >> Configure

lua << EOF
local telescope = require('telescope')
local actions = require('telescope.actions')


-- >> Setup telescope
telescope.setup{
    defaults = {
        mappings = {
            i = {
                -- Skip normal mode
                ["<esc>"] = actions.close,

                -- Add my own movement keys
                ["<C-j>"] = actions.move_selection_next,
                ["<C-k>"] = actions.move_selection_previous,
            }
        }
    }
}



-- >> Add Telescope Extensions

telescope.load_extension('fzy_native')
telescope.load_extension('coc')



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
        c = { function()
            -- % get's the current buffer's path
            -- :h get's the full path
            local buffer_relative_path = vim.call("expand", "%:h")
            builtin.file_browser({
                cwd = buffer_relative_path,
            })
        end, "Browse relative to buffer"},

        s = { builtin.live_grep, "Search file contents"},
        ["*"] = { builtin.grep_string, "Search for word under cursor"},
        ["/"] = { builtin.current_buffer_fuzzy_find, "Fuzzy find in the current buffer"},

        b = { builtin.buffers, "Buffers"},
        h = { builtin.help_tags, "Help tags"},
        y = { builtin.filetypes, "File types"},
        C = { builtin.colorscheme, "Colorschemes"},
        m = { builtin.keymaps, "Mappings"},

        B = { builtin.builtin, "Builtins"},
    },
    G = {
        name = "git",
        g = { ":G<CR>", "Branches"},

        b = { builtin.git_branches, "Branches"},
    },
}, { prefix = "<leader>", })
EOF
