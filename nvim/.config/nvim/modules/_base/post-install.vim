" _base/core.vim


" >> Keybinds

imap fd <Esc>
set timeoutlen=200



" >> Appearance

colorscheme wal
set hlsearch

" Note: these will only work in VTE compatible terminals (urxvt, st, etc.)
let &t_SI = "\<Esc>[6 q"         " IBeam shape in insert mode
let &t_SR = "\<Esc>[4 q"         " Underline shape in replace mode
let &t_EI = "\<Esc>[2 q"         " Block shape in normal mode



" >> Usability

set ignorecase
set smartcase



" >> Indentation

filetype plugin indent on

set tabstop=4    " Show existing tab with 4 spaces width
set shiftwidth=4 " When indenting with '>', use 4 spaces width
set expandtab    " On pressing tab, insert 4 spaces

