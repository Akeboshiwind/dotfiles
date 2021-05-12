" post-install.vim


" >> Vimspector config

" Set the basedir to look for all configs to inside the module
let g:vimspector_base_dir=expand('$HOME/.config/nvim/modules/vimspector/config/')



" >> Keybinds

nmap <leader>db :echom "Just setup a breakpoint then run the code"<CR>
nmap <leader>dsi <Plug>VimspectorStepInto
nmap <leader>dso <Plug>VimspectorStepOut
nmap <leader>dsv <Plug>VimspectorStepOver
