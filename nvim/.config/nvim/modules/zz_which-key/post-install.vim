" post-install.vim


" >> Register the mappings

call which_key#register(',', "g:which_key_map")

nnoremap <silent> <leader> :<c-u>WhichKey ','<CR>
vnoremap <silent> <leader> :<c-u>WhichKeyVisual ','<CR>
