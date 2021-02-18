" post-install.vim


" >> CoC extensions
 
call coc#add_extension('coc-json')



" >> Filetype conversions

au BufNewFile,BufRead Jenkinsfile setf groovy
