" =============================================================================
" Filename: indent/haskell.vim
" Author: itchyny
" License: MIT License
" Last Change: 2015/06/14 08:29:11.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

if exists('b:did_indent')
  finish
endif

let b:did_indent = 1

setlocal indentexpr=GetHaskellIndent()
setlocal indentkeys=o,O

function! GetHaskellIndent() abort

  if prevnonblank(v:lnum - 1) == 0
    return 0
  endif

  let nonblankline = getline(prevnonblank(v:lnum - 1))

  let line = getline(line('.') - 1)

  if nonblankline =~# '\<do\>$'
    return match(nonblankline, '^\s*\zs') + &shiftwidth
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

  if line =~# '^\s*\<where\>\s*$'
    return match(line, '^\s*\zswhere') + &shiftwidth
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

  return indent(prevnonblank(v:lnum - 1))

endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
