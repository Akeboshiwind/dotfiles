" .config/nmvim/init.vim


" >> Setup explanation

" The config in this repo is split into `module`s which live in the "modules"
" directory in neovim's config diretory.
"
" Each module contains a list of plugins to install and a set of vimscripts
" that are run at various points to configure or setup the module
"
"
" Each module *may* contain any or all of the following files:
"
" > plugins.vim
" A list of `Plug` commands to be executed during plugin installation
"
" > post-install.vim
" Code that needs to run after plugin installation
" Typically configures the installed plugins
"
" > pre-install.vim
" Code that needs to run before plugin installation




" >> Auto Install vim-plug

if empty(glob('~/.local/share/nvim/site/autoload/plug.vim'))
    silent !curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs
        \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif



" >> Utils

" Prefixes the given path the correct dotfiles directory
function! Dot(path)
    return "~/.config/nvim/" . a:path
endfunction



" >> Pre-Install scripts

" Sorted alphabetically, numbers first
for pre_install_file in sort(split(glob(Dot("modules/*/pre-install.vim")), "\n"))
    " `execute` actually resolves the variable
    execute "source" pre_install_file
endfor



" >> Plugins

call plug#begin(stdpath('data') . '/plugged')

for plugins_file in split(glob(Dot("modules/*/plugins.vim")), "\n")
    execute "source" plugins_file
endfor

call plug#end()



" >> Post-Install scripts

for post_install_file in split(glob(Dot("modules/*/post-install.vim")), "\n")
    execute "source" post_install_file
endfor
