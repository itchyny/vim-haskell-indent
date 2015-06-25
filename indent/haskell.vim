" =============================================================================
" Filename: indent/haskell.vim
" Author: itchyny
" License: MIT License
" Last Change: 2015/06/25 09:11:00.
" =============================================================================

if exists('b:did_indent')
  finish
endif

let b:did_indent = 1

setlocal indentexpr=GetHaskellIndent()
setlocal indentkeys=!^F,o,O,=where,=deri,<bar>

let s:save_cpo = &cpo
set cpo&vim

function! GetHaskellIndent() abort

  " =where
  if getline('.') =~# '\<where\>\s*$'
    return s:indent('^\s*\<where\>\s*$', '^\s*\%(\<where\>\)\?\s*\zs\h.*=', &shiftwidth)
  endif

  " =deriving
  if getline(v:lnum) =~# '\<deri\%[ving]\>\s*$'
    return s:indent('^\s*\<deri\%[ving]\>\s*$', '^.*\<data\>.*\zs=', 0)
  endif

  " |
  if getline('.') =~# '|\s*$'
    return s:indent_bar()
  endif

  if prevnonblank(v:lnum - 1) == 0
    return 0
  endif

  let nonblankline = getline(prevnonblank(v:lnum - 1))

  let line = getline(line('.') - 1)

  if nonblankline =~# '^\s*[^()\[\]{}]*[(\[{]\%([^()\[\]{}]*\|([^()\[\]{}]*)\|\[[^()\[\]{}]*\]\)*[-+/*\$&<>,]\?\s*$'
    if nonblankline =~# '[-+/*\$&<>,]\s*$'
      return match(nonblankline, '^\s*[^()\[\]{}]*[(\[{]\s*\zs')
    else
      return match(nonblankline, '^\s*[^()\[\]{}]*\zs[(\[{]')
    endif
  endif

  if nonblankline =~# '\<do\>\s*$'
    return match(nonblankline, '^\s*\%(\<where\>\|\<let\>\)\?\s*\zs') + &shiftwidth
  endif

  if nonblankline =~# '^\s*\<deriving\>'
    return s:indent('', '^.*\zs\<data\>.*=', 0)
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
    elseif nonblankline =~# '^\s*\<data\>.*='
      return match(line, '^.*\<data\>.*\zs=')
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

" a general indent function by searching the pattern upward
function! s:indent(linepattern, pattern, diff) abort
  let i = prevnonblank(v:lnum - 1)
  if i < v:lnum - 1
    return 0
  endif
  if getline(v:lnum) =~# a:linepattern
    while i > 0
      let line = getline(i)
      if line =~# a:pattern
        return match(line, a:pattern) + a:diff
      elseif line =~# '^\S'
        return -1
      endif
      let i -= 1
    endwhile
  endif
  return -1
endfunction

" |
function! s:indent_bar() abort
  if getline('.') =~# '^\s*|\s*$'
    let i = prevnonblank(v:lnum - 1)
    while i > 0
      let line = getline(i)
      if line =~# '^\s*\%(\<where\>\)\?.*[^|]|[^|].*='
        return match(line, '^\s*\%(\<where\>\)\?.*\zs|')
      elseif line =~# '\<data\>.*='
        return match(line, '^.*\<data\>.*\zs=')
      elseif line =~# '^\S'
        return -1
      endif
      let i -= 1
    endwhile
  endif
  return -1
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
