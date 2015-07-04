" =============================================================================
" Filename: indent/haskell.vim
" Author: itchyny
" License: MIT License
" Last Change: 2015/07/04 20:31:48.
" =============================================================================

if exists('b:did_indent')
  finish
endif

let b:did_indent = 1

setlocal indentexpr=GetHaskellIndent()
setlocal indentkeys=!^F,o,O,0=wher,=deri,=in,0<bar>,0==,0}

let s:save_cpo = &cpo
set cpo&vim

function! GetHaskellIndent() abort

  let line = getline(v:lnum)

  if line =~# '^\s*[{-]-'
    return line =~# '^\s*\%(-- |\|{-\)' ? 0 : indent(prevnonblank(v:lnum - 1))
  endif

  " where
  if line =~# '^\s*\<wher\%[e]\>'
    return s:indent('^\s*\<wher\%[e]\>', '^\s*\%(\<where\>\)\?\s*\zs\h.*=\|^\s*[^|]', &shiftwidth)
  endif

  " deriving
  if line =~# '\<deri\%[ving]\>'
    return s:indent('\<deri\%[ving]\>', line =~# '}\s*deri\%[ving]\>' ? '^.*\<data\>.*=\s*\zs' : '^.*\<data\>.*\zs=', 0)
  endif

  " in
  if line =~# '\<in\>'
    return s:indent('\<in\>', '^.*\<let\>\s*\zs', 0)
  endif

  " |
  if line =~# '|\s*$'
    return s:indent_bar()
  endif

  " =
  if line =~# '^\s*='
    return s:indent_eq()
  endif

  " }
  if line =~# '}$'
    return s:indent_brace()
  endif

  if prevnonblank(v:lnum - 1) == 0
    return 0
  endif

  let nonblankline = getline(prevnonblank(v:lnum - 1))

  let line = getline(v:lnum - 1)

  if nonblankline =~# '^\s*--'
    return indent(nonblankline)
  endif

  if nonblankline =~# '^\s*}\?[^()\[\]{}]*[(\[{]\%([^()\[\]{}]*\|([^()\[\]{}]*)\|\[[^()\[\]{}]*\]\)*[-+/*\$&<>,]\?\s*$'
    if nonblankline =~# '[-+/*\$&<>,]\s*$'
      return match(nonblankline, '^\s*}\?[^()\[\]{}]*[(\[{]\s*\zs')
    else
      return match(nonblankline, '^\s*}\?[^()\[\]{}]*\zs[(\[{]')
    endif
  endif

  if nonblankline =~# '\<do\>\s*$'
    return match(nonblankline, '^\s*\%(\<where\>\|.*\<let\>\)\?\s*\zs') + &shiftwidth
  endif

  if nonblankline =~# '\<deriving\>'
    return s:indent('', '^.*\zs\<data\>.*=', 0)
  endif

  if nonblankline =~# '^.*[^|]|[^|]' && nonblankline !~# '[.*|.*<-'
    if line =~# '^\s*$'
      if prevnonblank(v:lnum - 1) < v:lnum - 2
        return 0
      endif
      let i = v:lnum - 1
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

  if nonblankline =~# '[)}\]]\s*$'
    return s:unindent_after_parenthesis(prevnonblank(v:lnum - 1), match(nonblankline, '[)}\]]\s*$'))
  endif

  if nonblankline =~# '\<where\>'
    return s:after_where()
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

  if nonblankline =~# '^\s*\<data\>.*='
    return s:indent('', '^.*\<data\>.*\zs=', 0)
  endif

  if nonblankline =~# '::'
    return s:indent('', nonblankline =~# ',\s*$' ? '\S' : '{\s*\<\w\+\s*::', 0)
  endif

  if prevnonblank(v:lnum - 1) < v:lnum - 1
    let i = prevnonblank(v:lnum - 1)
    let where_clause = 0
    let indent = indent(prevnonblank(v:lnum - 1))
    while i
      let line = getline(i)
      if line =~# '\<where\>'
        let where_clause += 1
        if where_clause == v:lnum - prevnonblank(v:lnum - 1)
          return match(line, '^.*\<where\>\s*\zs')
        endif
      endif
      if 0 <= indent(i) && indent(i) < indent && line !~# '\<where\>\|^\s*|'
        return indent(i)
      endif
      let i -= 1
    endwhile
    return 0
  endif

  return indent(prevnonblank(v:lnum - 1))

endfunction

" a general indent function by searching the pattern upward
function! s:indent(linepattern, pattern, diff, ...) abort
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
        return a:0 ? a:1 : -1
      endif
      let i -= 1
    endwhile
  endif
  return -1
endfunction

" |
function! s:indent_bar() abort
  if getline(v:lnum) =~# '^\s*|\s*$'
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

" =
function! s:indent_eq() abort
  return match(getline(prevnonblank(v:lnum - 1)), '^\s*\%(\<where\>\|\<let\>\)\?\s*\zs') + &shiftwidth
endfunction

" }
function! s:indent_brace() abort
  let end = getpos('.')
  let view = winsaveview()
  normal! %
  let begin = getpos('.')
  call setpos('.', end)
  call winrestview(view)
  return begin[1] == end[1] ? -1 : begin[2] - 1
endfunction

" unindent after closed parenthesis
function! s:unindent_after_parenthesis(line, column) abort
  let i = prevnonblank(v:lnum - 1)
  if i < v:lnum - 2
    return 0
  endif
  let pos = getpos(v:lnum)
  let view = winsaveview()
  execute 'normal! ' a:line . 'gg' . (a:column + 1)  . '|'
  let end = getpos('.')
  normal! %
  let begin = getpos('.')
  call setpos('.', pos)
  call winrestview(view)
  if getline(begin[1]) =~# '\<deriving\>'
    let i = begin[1]
    while i
      let line = getline(i)
      if getline(i) =~# '\<data\>'
        return match(line, '\<data\>')
      elseif line =~# '^\S'
        return -1
      endif
      let i -= 1
    endwhile
  elseif getline(begin[1]) =~# '^\s*='
    return match(getline(prevnonblank(begin[1] - 1)), '^\s*\%(\<where\>\|\<let\>\)\?\s*\zs')
  endif
  return match(getline(begin[1]), '^\s*\%(\<where\>\|\<let\>\)\?\s*\zs')
endfunction

" where
function! s:after_where() abort
  let line = getline(prevnonblank(v:lnum - 1))
  if line =~# '\<where\>\s*$'
    let i = prevnonblank(v:lnum - 1)
    while i > 0
      let line = getline(i)
      if line =~# '\<module\>'
        return match(line, '\<module\>')
      elseif line =~# '\<class\|instance\>'
        return match(line, '\<class\|instance\>') + &shiftwidth
      elseif line =~# '^\S'
        return match(getline(prevnonblank(v:lnum - 1)), '\<where\>') + &shiftwidth
      endif
      let i -= 1
    endwhile
  elseif line =~# '^\s*\<where\>'
    return match(line, '\<where\>\s*\zs')
  else
    return indent(prevnonblank(v:lnum - 1))
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
