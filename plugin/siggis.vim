" Globals {{{

let g:siggis#sign_name = get(g:, 'siggis#sign_name', 'siggis')
let g:siggis#sign_text = get(g:, 'siggis#sign_text', '')
let g:siggis#sign_texthl = get(g:, 'siggis#sign_texthl', 'GitGutterChange')
let g:siggis#id_base = get(g:, 'siggis#id_base', 1000)

" }}}
" Define Siggis sign {{{

execute printf('sign define %s text=%s texthl=%s',
      \ g:siggis#sign_name,
      \ g:siggis#sign_text,
      \ g:siggis#sign_texthl)

" }}}
" siggis#write_file {{{

function! siggis#write_file (str, file)
  new
  setlocal buftype=nofile bufhidden=hide noswapfile nobuflisted
  put=a:str
  execute 'w ' a:file
  q
endfunction

" }}}
" siggis#write_signs_to_file {{{

function! siggis#write_signs_to_file (file)
  call siggis#write_file(join(siggis#get_all_sign_lines(), ','), a:file)
endfunction

" }}}
" siggis#load_signs {{{

function! siggis#load_signs (signs)
  for l:sign in a:signs
    call siggis#add_sign(l:sign)
  endfor
endfunction

" }}}
" siggis#load_signs_from_file {{{

function! siggis#load_signs_from_file (file)
  if (filereadable(a:file))
    let l:file = readfile(a:file)
    for l:lines in l:file
      if len(l:lines)
        call siggis#load_signs(split(l:lines, ','))
      endif
    endfor
  endif
endfunction

" }}}
" siggis#add_sign {{{

function! siggis#add_sign (...)
  if a:0 > 0
    let l:line = a:1
  else
    let l:line = line('.')
  endif

  execute printf('sign place %d line=%d name=%s buffer=%d',
        \ g:siggis#id_base + l:line,
        \ l:line,
        \ g:siggis#sign_name,
        \ bufnr('%'))
endfunction

" }}}
" siggis#remove_sign_by_id {{{

function! siggis#remove_sign_by_id (id)
  execute printf('sign unplace %d buffer=%d',
        \ a:id,
        \ bufnr('%'))
endfunction

" }}}
" siggis#remove_sign {{{

function! siggis#remove_sign (...)
  let l:sign = siggis#get_sign()
  if has_key(l:sign, 'id')
    call siggis#remove_sign_by_id(l:sign.id)
  endif
endfunction

" }}}
" siggis#remove_all_signs {{{

function! siggis#remove_all_signs ()
  let l:signs = siggis#get_all_signs()
  for l:sign in l:signs
    call siggis#remove_sign_by_id(l:sign.id)
  endfor
endfunction

" }}}
" siggis#toggle_sign {{{

function! siggis#toggle_sign (...)
  if a:0 > 0
    let l:line = a:1
  else
    let l:line = line('.')
  endif

  let l:signs = siggis#get_all_signs()
  for l:sign in l:signs
    if l:sign.line == l:line
      call siggis#remove_sign_by_id(l:sign.id)
      return
    elseif l:sign.line > l:line
      call siggis#add_sign(l:line)
      return
    endif
  endfor
  call siggis#add_sign(l:line)
endfunction

" }}}
" siggis#get_sign {{{

function! siggis#get_sign (...)
  if a:0 > 0
    let l:line = a:1
  else
    let l:line = line('.')
  endif
  let l:signs = siggis#get_all_signs()
  for l:sign in l:signs
    if l:sign.line == l:line
      return l:sign
    endif
  endfor
  return {}
endfunction

" }}}
" siggis#get_all_signs {{{

function! siggis#get_all_signs ()
  redir => l:sign_str | silent execute 'sign place' | redir END
  let l:signs_raw = split(l:sign_str, '\n')
  let l:signs = []
  for l:line in l:signs_raw
    if l:line =~ 'name='.g:siggis#sign_name
      let l:sign = {}
      let l:sign.line = substitute(l:line, '.*line=\([^ ]*\).*', '\1', '')
      let l:sign.id = substitute(l:line, '.*id=\([^ ]*\).*', '\1', '')
      let l:signs = add(l:signs, l:sign)
    endif
  endfor

  return l:signs
endfunction

" }}}
" siggis#get_all_sign_texts {{{

function! siggis#get_all_sign_texts (...)
  if a:0 > 0
    let l:signs = a:1
  else
    let l:signs = siggis#get_all_signs()
  endif

  let l:sign_texts = []
  for l:sign in l:signs
    let l:sign_texts = add(l:sign_texts, l:sign.line.': '.getbufline(bufnr('%'), l:sign.line)[0])
  endfor
  return l:sign_texts
endfunction

" }}}
" siggis#get_all_sign_lines {{{

function! siggis#get_all_sign_lines (...)
  if a:0 > 0
    let l:signs = a:1
  else
    let l:signs = siggis#get_all_signs()
  endif

  let l:sign_lines = []
  for l:sign in l:signs
    let l:sign_lines = add(l:sign_lines, l:sign.line)
  endfor
  return l:sign_lines
endfunction

" }}}
" siggis#open_unite {{{

function! siggis#open_unite ()
  let l:commands = []
  let l:signs = siggis#get_all_signs()
  let l:texts = siggis#get_all_sign_texts(l:signs)
  let l:idx = 0
  while l:idx < len(l:signs)
    let l:commands = add(l:commands, [l:texts[l:idx], l:signs[l:idx].line])
    let l:idx += 1
  endwhile
  let g:unite_source_menu_menus.siggis.command_candidates = l:commands
  Unite -silent menu:siggis
endfunction

let g:unite_source_menu_menus = get(g:,'unite_source_menu_menus',{})
let g:unite_source_menu_menus.siggis = {'description': 'Siggis'}

" }}}
" Siggis_find_project_root {{{

function! s:default_find_project_root ()
  let l:git = finddir('.git', '.;')
  let l:path = ''
  if len(l:git)
    let l:path = substitute(l:git, '/*.git$', '', '')
  endif
  if !len(l:path) | let l:path = expand('%:p:h') | endif
  return l:path
endfunction

function! s:find_project_root ()
  if exists('Siggis_find_project_root')
    return Siggis_find_project_root()
  endif
  return s:default_find_project_root()
endfunction

" }}}
" siggis#get_siggis_save_path {{{

function! siggis#get_siggis_save_path ()
  let l:file_path = expand('%:p:h')
  let l:rel_path = substitute(l:file_path, s:find_project_root(), '', '')
  if len(l:rel_path)
    let l:rel_path .= '/'
  endif
  let l:save_path = s:find_project_root() . '/.siggis/' . l:rel_path
  return l:save_path
endfunction

" }}}
" siggis#write_save_file {{{

function! siggis#write_save_file ()
  let l:path = expand('%:p:h')
  if l:path !~ '/.siggis'
    let l:save_path = siggis#get_siggis_save_path()
    if !isdirectory(l:save_path)
      " echom l:save_path
      call mkdir(substitute(l:save_path, '\.$', '', ''), 'p')
    endif
    call siggis#write_signs_to_file(l:save_path . expand('%:t'))
  endif
endfunction

" }}}
" siggis#load_save_file {{{

function! siggis#load_save_file ()
  let l:path = expand('%:p:h')
  if l:path !~ '/.siggis'
    let l:save_path = siggis#get_siggis_save_path()
    call siggis#load_signs_from_file(l:save_path . expand('%:t'))
  endif
endfunction

" }}}
