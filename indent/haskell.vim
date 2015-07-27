" =============================================================================
" Filename: indent/haskell.vim
" Author: itchyny
" License: MIT License
" Last Change: 2015/07/24 05:18:42.
" =============================================================================

if exists('b:did_indent')
  finish
endif

let b:did_indent = 1

setlocal indentexpr=GetHaskellIndent()
setlocal indentkeys=!^F,o,O,=wher,=deri,0=in,0=clas,0=inst,0=data,0=type,0<bar>,0==,0},0),0#

let s:save_cpo = &cpo
set cpo&vim

function! GetHaskellIndent() abort

  let line = getline(v:lnum)

  " comment
  if s:in_comment()
    let i = s:indent_comment()
    if i >= 0
      return i
    endif
  endif

  " #if, #else, #endif, #include
  if line =~# '^\s*\%(#$\|#\s*\w\+\)'
    return 0
  endif

  " where
  if line =~# '\<wher\%[e]\>'
    let i = s:indent_where()
    if i >= 0
      return i
    endif
  endif

  " deriving
  if line =~# '\<deri\%[ving]\>'
    return s:indent('\<deri\%[ving]\>', line =~# '}\s*deri\%[ving]\>' ? '^.*\<data\>.*=\s*\zs' : '^.*\<data\>.*\zs=', 0)
  endif

  " class, instance
  if line =~# '^\s*\<\%(clas\%[s]\|inst\%[ance]\|data\|type\)\>'
    return 0
  endif

  " |
  if line =~# '^\s*|\||\s*\%(--.*\)\?$'
    return s:indent_bar()
  endif

  " in
  if line =~# '^\s*\<in\>'
    return s:indent('^\s*\<in\>', '^.*\<let\>\s*\zs', 0, -1)
  endif

  " =
  if line =~# '^\s*='
    return s:indent_eq()
  endif

  " }, )
  if line =~# '^\s*[})]\s*\%(--.*\)\?$'
    return s:indent_parenthesis()
  endif

  if s:prevnonblank(v:lnum - 1) == 0
    return 0
  endif

  let nonblankline = getline(s:prevnonblank(v:lnum - 1))

  let line = getline(v:lnum - 1)

  " #if, #else, #endif, #include
  if nonblankline =~# '^\s*#'
    return 0
  endif

  if nonblankline =~# '^\s*--'
    return match(nonblankline, '\S')
  endif

  if nonblankline =~# '^\s*}\?[^()[\]{}]*[([{]\%([^()[\]{}]*\|([^()[\]{}]*)\|\[[^()[\]{}]*\]\)*[-+/*\$&<>,]\?\s*\%(--.*\)\?$'
    if nonblankline =~# '[([{]\s*\%(--.*\)\?$'
      return match(nonblankline, '^\s*\%(\<where\>\|.*\<let\>\)\?\s*\zs') + &shiftwidth
    elseif nonblankline =~# '[-+/*\$&<>,]\s*\%(--.*\)\?$'
      return match(nonblankline, '^\s*}\?[^()[\]{}]*[([{]\s*\zs')
    else
      return match(nonblankline, '^\s*}\?[^()[\]{}]*\zs[([{]')
    endif
  endif

  if nonblankline =~# '^\s*\<infix[rl]\?\>'
    return match(nonblankline, '\S')
  endif

  if nonblankline =~# '\<do\>\s*\%(--.*\)\?$'
    return match(nonblankline, '^\s*\%(\<where\>\|.*\<let\>\)\?\s*\zs') + &shiftwidth
  endif

  if nonblankline =~# '\<deriving\>'
    return s:indent('', '^.*\zs\<data\>.*=', 0)
  endif

  if nonblankline =~# '^.*[^|]|[^|].*='
    return s:after_guard()
  endif

  if nonblankline =~# '[)}\]]\s*\%(--.*\)\?$'
    return s:unindent_after_parenthesis(s:prevnonblank(v:lnum - 1), match(nonblankline, '[)}\]]\s*\%(--.*\)\?$'))
  endif

  if nonblankline =~# '\<where\>'
    return s:after_where()
  endif

  if nonblankline =~# '\<module\>' && nonblankline !~# ',\s*\%(--.*\)\?$' && indent(s:prevnonblank(v:lnum - 1)) < &shiftwidth
    return &shiftwidth
  endif

  if nonblankline =~# '^\s*\%([^()[\]{}]*\|([^()[\]{}]*)\|\[[^()[\]{}]*\]\)*\%([-+/*\$&<>=,]\+\|`\k\+`\)\s*\%(--.*\)\?$'
    return match(nonblankline, '^\s*\%(\<where\>\|.*\<let\>\)\?\s*\zs') +
          \ (nonblankline =~# '\<\%(where\|let\)\>\|=\%(--.*\)\?$' ? &shiftwidth : 0)
  endif

  if line =~# '\<if\>' && line !~# '^\s*#'
    if line =~# '\<then\>'
      return match(line, '.*\zs\<then\>')
    else
      return match(line, '.*\<if\>\s*\zs')
    endif
  endif

  if nonblankline =~# '\<else\>'
    let i = s:prevnonblank(v:lnum - 1)
    while i
      let line = getline(i)
      if getline(i) =~# '\<if\>'
        return match(line, '^\s*\zs')
      endif
      let i -= 1
    endwhile
  endif

  if line =~# '\<case\>.*\<of\>\s*\%(--.*\)\?$' && line !~# '^\s*#'
    return match(line, '.*\<case\>\s*\zs')
  endif

  if nonblankline =~# '->' && line =~# '^\s*\%(--.*\)\?$' || nonblankline =~# '^\s*_\s*->'
    let i = s:prevnonblank(v:lnum - 1)
    while i
      let line = getline(i)
      if getline(i) =~# '\<case\>'
        return match(line, '^\s*\zs')
      endif
      let i -= 1
    endwhile
  endif

  if nonblankline =~# '^\s*\<data\>.*='
    if nonblankline =~# '{-#\s*UNPACK\s*#-}' && getline(v:lnum) =~# '^\s*{-#\s*UNPACK\s*#-}'
      return match(nonblankline, '{-#\s*UNPACK\s*#-}')
    endif
    return s:indent('', '^.*\<data\>.*\zs=', 0)
  endif

  if nonblankline =~# '::'
    return s:indent('', nonblankline =~# ',\s*\%(--.*\)\?$' ? '\S' : '{\s*\<\w\+\s*::', 0, match(nonblankline, '\S'))
  endif

  if s:prevnonblank(v:lnum - 1) < v:lnum - 2 && line !~# '^\s*#'
    return 0
  elseif s:prevnonblank(v:lnum - 1) < v:lnum - 1 && line !~# '^\s*#'
    let i = s:prevnonblank(v:lnum - 1)
    let where_clause = 0
    let indent = indent(s:prevnonblank(v:lnum - 1))
    while i
      let line = getline(i)
      if line =~# '\<where\>' && indent(i) <= indent
        let where_clause += 1
        if where_clause == v:lnum - s:prevnonblank(v:lnum - 1)
          return match(line, '^.*\<where\>\s*\zs')
        endif
      endif
      if 0 <= indent(i) && indent(i) < indent && line !~# '\<where\>\|^\s*|\|^$'
        return line =~# '^\s*[([{]' ? indent : indent(i)
      endif
      if line =~# '^\s*\<\%(class\|instance\)\>' && getline(v:lnum) !~# '\<\%(class\|instance\)\>'
        return match(line, '^\s*\<\%(class\|instance\)\>') + &shiftwidth
      elseif line =~# '^\S'
        return 0
      endif
      let i -= 1
    endwhile
    return 0
  endif

  if indent(s:prevnonblank(s:prevnonblank(v:lnum - 1) - 1)) < indent(s:prevnonblank(v:lnum - 1))
        \ && nonblankline =~# '^\s*[-+/*$&<>=]' || getline(s:prevnonblank(s:prevnonblank(v:lnum - 1) - 1)) =~# '=\s*\%(--.*\)\?$'
    return indent(s:prevnonblank(s:prevnonblank(v:lnum - 1) - 1))
  endif

  return indent(s:prevnonblank(v:lnum - 1))

endfunction

" prevnonblank with skipping macros
function! s:prevnonblank(lnum) abort
  let i = a:lnum
  while i > 0
    let i = prevnonblank(i)
    if getline(i) !~# '^\s*#\s*\w\+'
      return i
    endif
    let i -= 1
  endwhile
  return 0
endfunction

" a general indent function by searching the pattern upward
function! s:indent(linepattern, pattern, diff, ...) abort
  let i = s:prevnonblank(v:lnum - 1)
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

" the cursor is in comment
function! s:in_comment() abort
  if getline(v:lnum) =~# '^\s*--'
    return 1
  endif
  let start = searchpos('\%(--.*\)\@<!{-', 'bcnW')
  let pos = getpos('.')
  let end = searchpos('\%(--.*\)\@<!-}', 'bcnW')
  return start != [0, 0] && (start[0] < pos[1] || start[0] == pos[1] && start[1] <= pos[2])
        \ && (end == [0, 0] || end[0] < start[0] || end[0] == start[0] && end[1] < start[1])
endfunction

" comment
function! s:indent_comment() abort
  if getline(s:prevnonblank(v:lnum - 1)) =~# '{-#\s*UNPACK\s*#-}' && getline(v:lnum) =~# '^\s*{-#\s*UNPACK\s*#-}'
    return match(getline(s:prevnonblank(v:lnum - 1)), '{-#\s*UNPACK\s*#-}')
  elseif getline(v:lnum) =~# '^\s*{-#\s*\<RULES\>\s*\%(--.*\)\?$'
    let name = matchstr(getline(v:lnum + 1), '^\s*"\zs\k\+\ze\%(/\k\+\)*"')
    if name !=# ''
      let i = v:lnum - 1
      while i
        if getline(i) =~# '^\s*\%(where\s\+\)\?\<' . name . '\>.*='
          return match(getline(i), '^\s*\%(\<where\>\)\?\s*\zs')
        endif
        let i -= 1
      endwhile
    endif
  endif
  if getline(v:lnum) =~# '^\s*{-#\s*\<\%(INLINE\|RULES\)\>'
    return -1
  elseif getline(v:lnum) =~# '^\s*\%({- |\|{-#.*#-}\s*\%(--.*\)\?$\|-- -\{10,\}\)'
    return 0
  endif
  if getline(v:lnum) =~# '^\s*[-{]-'
    let i = v:lnum
    if getline(i) =~# '^\s*--'
      while i <= line('$') && (getline(i) =~# '^\s*--' || getline(i) == '')
        let i += 1
      endwhile
      if getline(i) =~# '^\s*\<\%(class\|instance\|data\)\>'
        return match(getline(i), '^\s*\zs\<\%(class\|instance\|data\)\>')
      endif
    endif
    let i = s:prevnonblank(v:lnum - 1)
    let previndent = 0
    while i > 0
      let line = getline(i)
      let indent = indent(i)
      if line =~# '^\s*[-{]-'
        return indent
      elseif line =~# '^\s*\<\%(module\|class\|instance\)\>\|^\s*\<where\>\s*\%(--.*\)\?$' && line !~# ',\s*\%(--.*\)\?$' && line !~# '^\s\+\<module\>'
        return indent + &shiftwidth
      elseif line =~# '\s*(\s*\%(--.*\)\?$'
        return previndent ? previndent : indent + &shiftwidth
      elseif line =~# '^\S' && line !~# '^\s*#'
        return 0
      endif
      let previndent = indent
      let i -= 1
    endwhile
  endif
  let listpattern = '^\s*\%(\* @\|[a-z])\s\+\|>\s\+\)'
  if getline(v:lnum) =~# listpattern
    if getline(s:prevnonblank(v:lnum - 1)) =~# listpattern
      return indent(s:prevnonblank(v:lnum - 1))
    else
      if getline(v:lnum) =~# '^\s*[a-z])\s\+'
        let i = s:prevnonblank(v:lnum - 1)
        let indent = indent(i)
        while 0 < i && indent(i) == indent
          let i -= 1
        endwhile
        if 0 < i && getline(i) =~# '^\s*[a-z])\s\+'
          return indent(i)
        endif
      endif
      return indent(s:prevnonblank(v:lnum - 1)) + &shiftwidth
    endif
  endif
  if getline(v:lnum - 1) =~# '^\s*[a-z])\s\+'
    return match(getline(v:lnum - 1), '^\s*[a-z])\s\+\zs')
  endif
  if getline(v:lnum) !~# '^\s*\%(--.*\)\?$' && getline(s:prevnonblank(v:lnum - 1)) =~# listpattern
    return indent(s:prevnonblank(v:lnum - 1)) - &shiftwidth
  endif
  if getline(v:lnum) =~# '^\s*[-{]-'
    return 0
  endif
  let line = getline(s:prevnonblank(v:lnum - 1))
  if line =~# '^\s*{-#\s*\%(\s\+\w\+,\?\)\+'
    if line =~# ',\s*\%(--.*\)\?$'
      return match(line, '\zs\<\w\+,')
    else
      return match(line, '\w\+\s\+\zs\<\w\+') - &shiftwidth
    endif
  endif
  let i = s:prevnonblank(v:lnum - 1)
  if i < v:lnum - 1
    let indent = indent(i)
    while 0 < i && indent(i) == indent
      let i -= 1
    endwhile
    if 0 < i && getline(i) =~# '^\s*[a-z])\s\+'
      return indent(i) - &shiftwidth
    endif
  endif
  if getline(v:lnum) =~# '^\s*\%(#\?-}\|#$\)'
    let i = v:lnum - 1
    while 0 < i
      if getline(i) =~# '{-'
        return match(getline(i), '{-')
      endif
      let i -= 1
    endwhile
  endif
  return indent(s:prevnonblank(v:lnum - 1))
endfunction

" |
function! s:indent_bar() abort
  if getline(v:lnum) =~# '^\s*|'
    let i = s:prevnonblank(v:lnum - 1)
    let indent = indent(i)
    while i > 0
      let line = getline(i)
      if line =~# '^\s*\%(\<where\>\)\?.*[^|]|[^|].*='
        return match(line, '^\s*\%(\<where\>\)\?.*[^|]\zs|[^|].*=')
      elseif line =~# '\<data\>.*='
        return match(line, '^.*\<data\>.*\zs=')
      elseif line =~# '^\s*\<where\>\s*\%(--.*\)\?$' && indent(i) < indent
        return indent + &shiftwidth
      elseif line =~# '^\S'
        return &shiftwidth
      endif
      let indent = indent(i)
      let i = s:prevnonblank(i - 1)
    endwhile
  endif
  return -1
endfunction

" guard
function! s:after_guard() abort
  let nonblankline = getline(s:prevnonblank(v:lnum - 1))
  let line = getline(v:lnum - 1)
  if line =~# '^\s*\%(--.*\)\?$'
    if s:prevnonblank(v:lnum - 1) < v:lnum - 2
      return 0
    endif
    let i = v:lnum - 1
    let where_clause = 0
    while i
      let line = getline(i)
      if line =~# '^\S'
        return 0
      endif
      if where_clause && line !~# '^\s*\%(--.*\)\?$' && line !~# '^\s*|[^|]'
        return match(line, '^\s*\%(\<where\>\)\?\s*\zs')
      endif
      if line =~# '\<where\>'
        let where_clause = 1
      endif
      let i -= 1
    endwhile
  endif
  if nonblankline =~# '[^|]|\s*\%(otherwise\|True\|0\s*<\s*1\|1\s*>\s*0\)' || getline(v:lnum) =~# '^\s*\S'
    let i = s:prevnonblank(v:lnum - 1)
    while i
      let line = getline(i)
      if line !~# '^\s*\%(--.*\)\?$' && line !~# '^\s*|'
        return match(line, '^\s*\%(\<where\>\)\?\s*\zs')
      endif
      let i -= 1
    endwhile
  elseif nonblankline =~# '^\s*\<data\>.*='
    return match(line, '^.*\<data\>.*\zs=')
  else
    return match(line, '^.*[^|]\zs|[^|].*=')
  endif
endfunction

" =
function! s:indent_eq() abort
  return match(getline(s:prevnonblank(v:lnum - 1)), '^\s*\%(\<where\>\|\<let\>\)\?\s*\zs') + &shiftwidth
endfunction

" }, )
function! s:indent_parenthesis() abort
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
  let i = s:prevnonblank(v:lnum - 1)
  if i < v:lnum - 2
    return 0
  endif
  let pos = getpos('.')
  let view = winsaveview()
  execute 'normal! ' a:line . 'gg' . (a:column + 1)  . '|'
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
    return match(getline(s:prevnonblank(begin[1] - 1)), '^\s*\%(\<where\>\|\<let\>\)\?\s*\zs')
  elseif getline(s:prevnonblank(begin[1] - 1)) =~# '=\s*\%(--.*\)\?$'
    return match(getline(s:prevnonblank(begin[1] - 1)), '^\s*\%(\<where\>\|\<let\>\)\?\s*\zs')
  endif
  return match(getline(begin[1]), '^\s*\%(\<where\>\|\<let\>\)\?\s*\zs')
endfunction

" where
function! s:indent_where() abort
  if getline(v:lnum) =~# '^\s*\<wher\%[e]\>'
    let i = s:prevnonblank(v:lnum - 1)
    while i > 0
      let line = getline(i)
      if line =~# '^\s*\%(\<where\>\)\?\s*\zs\h.*=\|^\s*[^| ]'
        return match(line, '^\s*\%(\<where\>\)\?\s*\zs\h.*=\|^\s*[^| ]') + &shiftwidth
      elseif line =~# '^\S'
        return -1
      endif
      let i -= 1
    endwhile
  elseif getline(v:lnum) =~# '^\s*)\s*\<wher\%[e]\>'
    let pos = getpos('.')
    let view = winsaveview()
    execute 'normal! ' (match(getline(v:lnum), ')') + 1)  . '|%'
    let begin = getpos('.')
    call setpos('.', pos)
    call winrestview(view)
    if getline(begin[1]) =~# '\<module\|class\|instance\>'
      return indent(begin[1]) + &shiftwidth
    elseif getline(s:prevnonblank(begin[1] - 1)) =~# '\<module\|class\|instance\>'
      return indent(s:prevnonblank(begin[1] - 1)) + &shiftwidth
    endif
  endif
  return -1
endfunction

" where
function! s:after_where() abort
  let line = getline(s:prevnonblank(v:lnum - 1))
  if line =~# '^\s*)\s*\<where\>\s*\%(--.*\)\?$'
    let pos = getpos('.')
    let view = winsaveview()
    execute 'normal! ' s:prevnonblank(v:lnum - 1) . 'gg^%'
    let begin = getpos('.')
    call setpos('.', pos)
    call winrestview(view)
    if getline(begin[1]) =~# '\<module\|class\|instance\>'
      return 0
    endif
  endif
  if line =~# '\<where\>\s*\%(--.*\)\?$'
    let i = s:prevnonblank(v:lnum - 1)
    while i > 0
      let line = getline(i)
      if line =~# '^\s*\<module\>'
        return 0
      elseif line =~# '^\s*\<\%(class\|instance\)\>'
        if line =~# '\<where\>\s*\%(--.*\)\?$' && i != s:prevnonblank(v:lnum - 1)
          break
        endif
        return match(line, '\<class\|instance\>') + &shiftwidth
      elseif line =~# '^\S' && line !~# '^--'
        return match(getline(s:prevnonblank(v:lnum - 1)), '\<where\>') + &shiftwidth
      endif
      let i -= 1
    endwhile
  endif
  if line =~# '^\s*\<where\>'
    if s:prevnonblank(v:lnum - 1) < v:lnum - 2
      return 0
    elseif s:prevnonblank(v:lnum - 1) < v:lnum - 1
      let i = s:prevnonblank(v:lnum - 1) - 1
      let indent = indent(s:prevnonblank(v:lnum - 1))
      while i
        let line = getline(i)
        if line =~# '^\S'
          return 0
        elseif indent(i) < indent
          return match(line, '^\s*\%(\<where\>\)\?\s*\zs')
        endif
        let i -= 1
      endwhile
      return 0
    endif
    return match(line, '\<where\>\s*\zs')
  endif
  if getline(s:prevnonblank(v:lnum - 1)) =~# '^\s*\<where\>\s*\%(--.*\)\?$'
    return indent(s:prevnonblank(v:lnum - 1)) + &shiftwidth
  endif
  return indent(s:prevnonblank(v:lnum - 1))
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
