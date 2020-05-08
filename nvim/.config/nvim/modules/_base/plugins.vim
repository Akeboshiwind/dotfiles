" _base/plugins.vim


" >> Plugins

" Some sensible defaults for vim
Plug 'tpope/vim-sensible'

" A colorscheme for use with wal
Plug 'dylanaraps/wal.vim'

" Intelligently reopen files at your last edit position in Vim
Plug 'farmergreg/vim-lastplace'

" Seamless navigation between tmux panes and vim splits
Plug 'christoomey/vim-tmux-navigator'

" Fzf <3 vim
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" Terraform
Plug 'hashivim/vim-terraform'

" YAML
Plug 'stephpy/vim-yaml'

" Avro
Plug 'gurpreetatwal/vim-avro'

