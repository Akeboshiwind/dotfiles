" post-install.vim


" >> Theme

set t_Co=256

set background=light
colorscheme gruvbox8_hard



" >> Appearance

set hlsearch

" Note: these will only work in VTE compatible terminals (urxvt, st, etc.)
let &t_SI = "\<Esc>[6 q"         " IBeam shape in insert mode
let &t_SR = "\<Esc>[4 q"         " Underline shape in replace mode
let &t_EI = "\<Esc>[2 q"         " Block shape in normal mode



" >> Statusline
" see :help statusline for more info on the codes here

function! StatuslineCwd()
    let l:relativePath = expand('%')
    let l:parts = split(l:relativePath, '/')

    " Shorten parent folders to be l:n characters
    " Keep the filename the same length
    let l:n = 1
    for idx in range(len(l:parts)-1)
        let l:parts[idx]=l:parts[idx][0:n-1]
    endfor

    return join(l:parts, '/')
endfunction

set statusline=
set statusline=%{StatuslineCwd()}

" Separate the start and the end
set statusline+=%=

" Line number and file length & column number
set statusline+=\ %l/%L:%c\ 
" Padding at the end
set statusline+=" "
