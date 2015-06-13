" =============================================================================
" Filename: indent/haskell.vim
" Author: itchyny
" License: MIT License
" Last Change: 2015/06/14 02:05:23.
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

  let line = getline(line('.') - 1)

  if line =~# '^\s*where *$'
    return match(line, '^\s*\zswhere') + &shiftwidth
  endif

  if line =~# '^\s*where'
    return match(line, '^\s*where *\zs')
  endif

  return indent(prevnonblank(v:lnum - 1))

endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
