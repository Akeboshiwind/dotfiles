" post-install.vim


" >> Vimspector config

" Set the basedir to look for all configs to inside the module
let g:vimspector_base_dir=expand('$HOME/.config/nvim/modules/vimspector/config/')



" >> Keybinds

nmap <leader>db :echom "Just setup a breakpoint then run the code"<CR>

nmap <leader>dc <Plug>VimspectorContinue
nmap <leader>dq <Plug>VimspectorStop
nmap <leader>dr <Plug>VimspectorRestart
nmap <leader>dp <Plug>VimspectorPause
nmap <leader>de <Plug>VimspectorBalloonEval

nmap <leader>dtb <Plug>VimspectorToggleBreakpoint
nmap <leader>dtc <Plug>VimspectorToggleConditionalBreakpoint
nmap <leader>dta <Plug>VimspectorAddFunctionBreakpoint

nmap <leader>dsr <Plug>VimspectorRunToCursor
nmap <leader>dsi <Plug>VimspectorStepInto
nmap <leader>dso <Plug>VimspectorStepOut
nmap <leader>dsv <Plug>VimspectorStepOver



" >> Which Key Mappings

let g:which_key_map['d'] = {
            \ 'name': '+debug',
            \ 'b': 'show-reminder',
            \ 'c': 'continue',
            \ 'q': 'stop',
            \ 'r': 'restart',
            \ 'p': 'pause',
            \ 'e': 'eval-selection',
            \ 't': {
                \ 'name': '+toggle',
                \ 'b': 'breakpoint',
                \ 'c': 'conditional-breakpoint',
                \ 'a': 'add-function-breakpoint',
                \ }
            \ 's': {
                \ 'name': '+step',
                \ 'r': 'run-to-cursor',
                \ 'i': 'into',
                \ 'o': 'out',
                \ 'v': 'over',
                \ }
            \ }
