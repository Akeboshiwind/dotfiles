" post-install.vim


" >> Theme

syntax enable

if exists('+termguicolors')
    " Not sure what these bits do tbh
    let &t_8f="\<Esc>[38;2;%lu;%lu;%lum"
    let &t_8b="\<Esc>[48;2;%lu;%lu;%lum"
    " Tell nvim that terminal support truecolor
    " Can test using the truecolor-test script in bin or at:
    " https://gist.github.com/XVilka/8346728
    set termguicolors
endif

set background=dark
" High contrast is best contrast
colorscheme solarized8_high



" >> Appearance

set hlsearch

" Note: these will only work in VTE compatible terminals (urxvt, st, etc.)
let &t_SI = "\<Esc>[6 q"         " IBeam shape in insert mode
let &t_SR = "\<Esc>[4 q"         " Underline shape in replace mode
let &t_EI = "\<Esc>[2 q"         " Block shape in normal mode



" >> Statusline
" see :help statusline for more info on the codes here

function! ShortPath(path)
    " If the path is empty or doesn't look like a path, return early
    if a:path == ""
        return ""
    elseif stridx(a:path, '/') == -1
        return a:path
    endif

    let l:parts = split(a:path, '/')

    " Shorten parent folders to be l:n characters
    " Keep the filename the same length
    let l:n = 1
    for idx in range(len(l:parts)-1)
        let l:parts[idx]=l:parts[idx][0:n-1]
    endfor

    let l:shortPath = join(l:parts, '/')

    " If the path isn't relative, add back in the beginning slash
    if a:path[0] == '/'
        return '/' . l:shortPath
    else
        return l:shortPath
    endif
endfunction

function! StatuslineCwd()
    let l:relativePath = expand('%')

    if l:relativePath == ""
        " We're in an unnamed buffer, so just default the file name
        return "[unnamed]"
    else
        return ShortPath(l:relativePath)
    endif
endfunction

set statusline=
set statusline=%{StatuslineCwd()}

" Separate the start and the end
set statusline+=%=

" Line number and file length & column number
set statusline+=\ %l/%L:%c\ 
" Padding at the end
set statusline+=" "
