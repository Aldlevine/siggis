" Source {{{

execute 'source '.expand('<sfile>:p:h').'/plugin/siggis.vim'

" }}}
" Mapping {{{

autocmd BufWrite * call siggis#write_save_file()
autocmd VimEnter,BufRead * call siggis#load_save_file()
autocmd BufEnter * nnoremap <silent> <c-b> :call siggis#toggle_sign()<CR>
autocmd BufEnter * nnoremap <silent> <c-n> :call siggis#open_unite()<CR>

" }}}
