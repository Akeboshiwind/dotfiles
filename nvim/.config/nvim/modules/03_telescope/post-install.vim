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
        name = "file",
        f = { builtin.find_files, "Search local files"},
        g = { builtin.git_files, "Search files in current git repo"},
        b = { builtin.buffers, "Search buffers"},
        h = { builtin.help_tags, "Search help"},
    },
}, { prefix = "<leader>", })
EOF
