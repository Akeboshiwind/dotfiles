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
        s = { builtin.live_grep, "Search file contents"},
        r = { builtin.grep_string, "Search for word under cursor"},

        b = { builtin.buffers, "Buffers"},
        h = { builtin.help_tags, "Help tags"},
        t = { builtin.filetypes, "File types"},
        c = { builtin.colorscheme, "Colorschemes"},
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
