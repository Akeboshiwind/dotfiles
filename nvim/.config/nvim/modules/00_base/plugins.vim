" plugins.vim


" >> Plugins

" Some sensible defaults for vim
Plug 'tpope/vim-sensible'

" Intelligently reopen files at your last edit position in Vim
Plug 'farmergreg/vim-lastplace'

" Seamless navigation between tmux panes and vim splits
Plug 'christoomey/vim-tmux-navigator'

" Automatically create paths that don't exist on buffer save
Plug 'arp242/auto_mkdir2.vim'

" Git plugin
Plug 'tpope/vim-fugitive'

" Fzf <3 vim
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
