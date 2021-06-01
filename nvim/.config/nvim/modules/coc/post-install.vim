" post-install.vim


" >> Config

" Setup the config to be inside the module
let g:coc_config_home=expand("$HOME/.config/nvim/modules/coc/")



" >> Vim Settings
" NOTE: The below is heavily based on the README of CoC
"       The recommended config may change so it's best to check for updates

" TextEdit might fail if hidden is not set.
set hidden

" Some servers have issues with backup files, see #649.
set nobackup
set nowritebackup

" Give more space for displaying messages.
set cmdheight=2

" Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
" delays and poor user experience.
set updatetime=300

" Don't pass messages to |ins-completion-menu|.
set shortmess+=c

" Always show the signcolumn, otherwise it would shift the text each time
" diagnostics appear/become resolved.
if has("patch-8.1.1564")
  " Recently vim can merge signcolumn and number column into one
  set signcolumn=number
else
  set signcolumn=yes
endif



" >> Completion

" Use tab for trigger completion with characters ahead and navigate.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-space> to trigger completion.
if has('nvim')
  inoremap <silent><expr> <c-space> coc#refresh()
else
  inoremap <silent><expr> <c-@> coc#refresh()
endif

" Make <CR> auto-select the first completion item and notify coc.nvim to
" format on enter, <cr> could be remapped by other vim plugin
inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"



" >> Scrolling for popups
" TODO: Move to WhichKey?

" Remap <C-f> and <C-b> for scroll float windows/popups.
if has('nvim-0.4.0') || has('patch-8.2.0750')
  nnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
  nnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
  inoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<cr>" : "\<Right>"
  inoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<cr>" : "\<Left>"
  vnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
  vnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
endif



" >> Highlighting

" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')



" >> Docs

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  elseif (coc#rpc#ready())
    call CocActionAsync('doHover')
  else
    execute '!' . &keywordprg . " " . expand('<cword>')
  endif
endfunction



" >> Formatting
" TODO: Find out what this actually does

augroup mygroup
  autocmd!
  " Setup formatexpr specified filetype(s).
  autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
  " Update signature help on jump placeholder.
  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end



" >> Mappings

lua << EOF
local wk = require("which-key")
local telescope = require('telescope')

wk.register({
    -- >> Visual selections

    -- NOTE: Requires 'textDocument.documentSymbol' support from
    --       the language server.
    ["if"] = { "<Plug>(coc-funcobj-i)", "Inside function", mode = "x" },
    ["if"] = { "<Plug>(coc-funcobj-i)", "Inside function", mode = "o" },
    af = { "<Plug>(coc-funcobj-a)", "Around function", mode = "x" },
    af = { "<Plug>(coc-funcobj-a)", "Around function", mode = "o" },
    ic = { "<Plug>(coc-classobj-i)",
           "Inside class/struct/interface",
           mode = "x" },
    ic = { "<Plug>(coc-classobj-i)",
           "Inside class/struct/interface",
           mode = "o" },
    ac = { "<Plug>(coc-classobj-a)",
           "Around class/struct/interface",
           mode = "x" },
    ac = { "<Plug>(coc-classobj-a)",
           "Around class/struct/interface",
           mode = "o" },



    -- >> Selection
    -- TODO: Move back
    -- TODO: Ask for "force"?

    -- NOTE: Requires 'textDocument/selectionRange' support from
    --       the language server.
    --       coc-tsserver, coc-python are the examples of servers that support it
    ["<TAB>"] = { "<Plug>(coc-range-select)", "Select range" },
    ["<TAB>"] = { "<Plug>(coc-range-select)", "Select range", mode = "x" },



    -- >> Selection
    -- TODO: Move back
    -- TODO: Ask for "force"?

    K = { show_documentation, "Show documentation" },



    -- >> Organised stuff
    -- TODO: Split appart?

    ["<leader>"] = {
        -- >> Code Actions
        -- Example: `<leader>laap` for current paragraph
        a = {
            name = "action",
            a = { "<Plug>(coc-codeaction-selected)",
                  "Apply code action for region" },
            a = { "<Plug>(coc-codeaction-selected)",
                  "Apply code action for region",
                  mode = "x", },
            c = { "<Plug>(coc-codeaction)", "Apply code action for buffer" },
        }, 

        -- >> List Commands
        l = {
            name = "list",
            c = { telescope.extensions.coc.commands, "Commands" },
            s = { function() telescope.extensions.coc.document_symbols({}) end,
                  "Document Symbols" },
            S = { function() telescope.extensions.coc.workspace_symbols({}) end,
                  "Workspace Symbols" },
            a = { telescope.extensions.coc.line_code_actions,
                  "Code Actions on Line" },
            b = { telescope.extensions.coc.file_code_actions,
                  "Code Actions in Buffer" },
            d = { telescope.extensions.coc.diagnostics, "Diagnostics" },
            D = { telescope.extensions.coc.workspace_diagnostics,
                  "Workspace Diagnostics" },

            -- TODO: Ask for telescope support
            e = { ":<C-u>CocList extensions<cr>", "Extensions" },

            -- Remove these when swapping to Telescope?
            p = { ":<C-u>CocListResume<cr>", "Resume List" },
            j = { ":<C-u>CocNext<cr>", "Next" },
            k = { ":<C-u>CocPrev<cr>", "Previous" },
        }, 

        -- >> Diagnostics
        -- Remove these when swapping to Telescope?
        D = {
            name = "diagnostics",
            l = { ":<C-u>CocList diagnostics<cr>", "List" },
            n = { "<Plug>(coc-diagnostic-next)", "Next" },
            p = { "<Plug>(coc-diagnostic-prev)", "Previous" },
        }, 

        -- >> Goto code navigation
        g = {
            name = "goto",
            d = { "<Plug>(coc-definition)", "Definition" },
            y = { "<Plug>(coc-type-definition)", "Type Definition" },
            i = { "<Plug>(coc-implementation)", "Implementation" },
            r = { "<Plug>(coc-references)", "References" },
        }, 

        -- >> Things that don't fit elsewhere
        r = {
            name = "run",

            n = { "<Plug>(coc-rename)", "Rename symbol under cursor" },
            f = { "<Plug>(coc-format-selected)", "Fomat selected code" },
            f = { "<Plug>(coc-format-selected)",
                  "Fomat selected code",
                  mode = "x" },

            q = { "<Plug>(coc-fix-current)", "Apply AutoFix to current line" },

            -- >> Code Lens
            -- Make sure `"codeLens.enable": true` is set in your coc config
            l = { ":<C-u>call CocActionAsync('codeLensAction')<CR>",
                  "Apply code action for region" },
        },

    },
}, {})
EOF
