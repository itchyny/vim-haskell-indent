" =============================================================================
" Filename: indent/haskell.vim
" Author: itchyny
" License: MIT License
" Last Change: 2015/06/21 21:07:54.
" =============================================================================

if exists('b:did_indent')
  finish
endif

let b:did_indent = 1

setlocal indentexpr=GetHaskellIndent()
setlocal indentkeys=!^F,o,O,=where

let s:save_cpo = &cpo
set cpo&vim

function! GetHaskellIndent() abort

  " =where
  if getline('.') =~# '\<where\>\s*$'
    return s:reindent_where()
  endif

  if prevnonblank(v:lnum - 1) == 0
    return 0
  endif

  let nonblankline = getline(prevnonblank(v:lnum - 1))

  let line = getline(line('.') - 1)

  if nonblankline =~# '\<do\>\s*$'
    return match(nonblankline, '^\s*\%(\<where\>\|\<let\>\)\?\s*\zs') + &shiftwidth
  endif

  if nonblankline =~# '^.*[^|]|[^|]'
    if line =~# '^\s*$'
      if prevnonblank(v:lnum - 1) < line('.') - 2
        return 0
      endif
      let i = line('.') - 1
      let where_clause = 0
      while i
        let line = getline(i)
        if line =~# '^\S'
          return 0
        endif
        if where_clause && line !~# '^\s*$' && line !~# '^\s*|[^|]'
          return match(line, '^\s*\%(\<where\>\)\?\s*\zs')
        endif
        if line =~# '\<where\>'
          let where_clause = 1
        endif
        let i -= 1
      endwhile
    endif
    if nonblankline =~# '[^|]|\s*\%(otherwise\|True\|0\s*<\s*1\|1\s*>\s*0\)'
      let i = prevnonblank(v:lnum - 1)
      while i
        let line = getline(i)
        if line !~# '^\s*$' && line !~# '^\s*|'
          return match(line, '^\s*\%(\<where\>\)\?\s*\zs')
        endif
        let i -= 1
      endwhile
    else
      return match(line, '^.*[^|]\zs|[^|]')
    endif
  endif

  if line =~# '^.*\<where\>\s*$'
    return match(line, '^.*\zs\<where\>') + &shiftwidth
  endif

  if line =~# '^\s*\<where\>'
    return match(line, '^\s*\<where\>\s*\zs')
  endif

  if line =~# '\<if\>'
    if line =~# '\<then\>'
      return match(line, '.*\zs\<then\>')
    else
      return match(line, '.*\<if\>\s*\zs')
    endif
  endif

  if nonblankline =~# '\<else\>'
    let i = prevnonblank(v:lnum - 1)
    while i
      let line = getline(i)
      if getline(i) =~# '\<if\>'
        return match(line, '^\s*\zs')
      endif
      let i -= 1
    endwhile
  endif

  if line =~# '\<case\>.*\<of\>\s*$'
    return match(line, '.*\<case\>\s*\zs')
  endif

  if nonblankline =~# '->' && line =~# '^\s*$' || nonblankline =~# '^\s*_\s*->'
    let i = prevnonblank(v:lnum - 1)
    while i
      let line = getline(i)
      if getline(i) =~# '\<case\>'
        return match(line, '^\s*\zs')
      endif
      let i -= 1
    endwhile
  endif

  if prevnonblank(v:lnum - 1) < line('.') - 1
    let i = prevnonblank(v:lnum - 1)
    let where_clause = 0
    let indent = indent(prevnonblank(v:lnum - 1))
    while i
      let line = getline(i)
      if line =~# '\<where\>'
        let where_clause += 1
        if where_clause == line('.') - prevnonblank(v:lnum - 1)
          return match(line, '^.*\<where\>\s*\zs')
        endif
      endif
      if 0 <= indent(i) && indent(i) < indent && line !~# '\<where\>'
        return indent(i)
      endif
      let i -= 1
    endwhile
    return 0
  endif

  return indent(prevnonblank(v:lnum - 1))

endfunction

" =where
function! s:reindent_where() abort
  if getline('.') =~# '^\s*\<where\>\s*$'
    let i = prevnonblank(v:lnum - 1)
    while i > 0
      let line = getline(i)
      if line =~# '^\s*\%(\<where\>\)\?\s*\h.*='
        return match(line, '^\s*\%(\<where\>\)\?\s*\zs') + &shiftwidth
      endif
      let i -= 1
    endwhile
  endif
  return -1
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
