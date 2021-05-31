" post-install.vim


" >> Setup

lua << EOF
local actions = require('telescope.actions')

require('telescope').setup{
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
require('telescope').load_extension('fzy_native')
require('telescope').load_extension('coc')
EOF



" >> Mappings

nnoremap <leader>ff <cmd>lua require('telescope.builtin').find_files()<cr>
nnoremap <leader>fg <cmd>lua require('telescope.builtin').git_files()<cr>
nnoremap <leader>fb <cmd>lua require('telescope.builtin').buffers()<cr>
nnoremap <leader>fh <cmd>lua require('telescope.builtin').help_tags()<cr>
