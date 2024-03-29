" .vimrc


" >> Plugins

" Auto-install vim-plug
let data_dir = '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')

Plug 'tpope/vim-sensible'

Plug 'farmergreg/vim-lastplace'

Plug 'christoomey/vim-tmux-navigator'

Plug 'hashivim/vim-terraform'

Plug 'stephpy/vim-yaml'

Plug 'gurpreetatwal/vim-avro'

call plug#end()



" >> Keybinds

imap fd <Esc>
set timeoutlen=200



" >> Appearance

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
