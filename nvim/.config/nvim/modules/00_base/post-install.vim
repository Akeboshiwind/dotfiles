" post-install.vim


" >> Keybinds

let mapleader = ","
imap fd <Esc>
set timeoutlen=400

" Search for the word currently under the cursor
nnoremap <silent><leader>rg :Rg <C-R><C-W><CR>



" >> Usability

set ignorecase
set smartcase
set splitright
set inccommand=nosplit



" >> Indentation

filetype plugin indent on

set tabstop=4    " Show existing tab with 4 spaces width
set shiftwidth=4 " When indenting with '>', use 4 spaces width
set expandtab    " On pressing tab, insert 4 spaces


" >> Which Key Mappings

let g:which_key_map['rg'] = 'ripgrep-cursor'
" Hide group, but show docname if prompted
let g:which_key_map['r'] = {
            \'name': 'which_key_ignore',
            \'g': 'ripgrep-cursor',
            \}
