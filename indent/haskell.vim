" =============================================================================
" Filename: indent/haskell.vim
" Author: itchyny
" License: MIT License
" Last Change: 2015/06/14 02:58:50.
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
    if nonblankline =~# '[^|]|\s*\%(otherwise\|True\|0\s*<\s*1\|1\s*>\s*0\)'
      let i = prevnonblank(v:lnum - 1)
      while i
        let line = getline(i)
        if getline(i) !~# '^\s*|'
          return match(line, '^\s*\zs')
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

  return indent(prevnonblank(v:lnum - 1))

endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
