" =============================================================================
" Filename: indent/haskell.vim
" Author: itchyny
" License: MIT License
" Last Change: 2022/10/30 09:56:27.
" =============================================================================

if exists('b:did_indent')
  finish
endif

let b:did_indent = 1

setlocal indentexpr=GetHaskellIndent()
setlocal indentkeys=!^F,o,O,=wher,=deri,0=in,0=class,0=instance,0=data,0=type,0=else,0<bar>,0},0],0(,0),0#,0,0==

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
  if line =~# '\v^\s*(#$|#\s*\w+)'
    return 0
  endif

  " where
  if line =~# '\v<wher%[e]>'
    let i = s:indent_where()
    if i >= 0
      return i
    endif
  endif

  " deriving
  if line =~# '\v^\s*<deri%[ving]>'
    if line =~# '\v^\s*}\s*deri%[ving]>'
      return s:indent_parenthesis()
    endif
    return s:indent('\v<deri%[ving]>', '\v^.*<data>.*\zs\=', 0)
  endif

  " class, instance
  if line =~# '\v^\s*<(class|instance)>'
    return 0
  endif

  " else
  if line =~# '\v^\s*<else>'
    return s:indent_else()
  endif

  " |
  if line =~# '\v^\s*\||\|(\s*--.*)?$'
    return s:indent_bar()
  endif

  " in
  if line =~# '\v^\s*<in>'
    return s:indent('\v^\s*<in>', '\v^.*<let>\s*\zs', 0, -1)
  endif

  " =
  if line =~# '\v^\s*\='
    return s:indent_eq()
  endif

  " }, ], )
  if line =~# '\v^\s*[})\]]'
    return s:indent_parenthesis()
  endif

  if s:prevnonblank(v:lnum - 1) == 0
    return 0
  endif

  let nonblankline = getline(s:prevnonblank(v:lnum - 1))

  " data, type
  if line =~# '\v^\s*<(data|type)>' && nonblankline !~# '\v<(class|instance)>.*<where>'
    return 0
  endif

  let noparen = '[^()[\]{}]'
  let noparen = '%(' . noparen . '+|\(' . noparen . '*\)|\['  . noparen . '*\])'
  let noparen = '%(' . noparen . '+|\(' . noparen . '*\)|\['  . noparen . '*\])*'

  if line =~# '\v^\s*,' . noparen . '(\s*--.*)?$' && nonblankline =~# '\v^\s*,'
    return match(nonblankline, '^\s*\zs,')
  endif

  let line = getline(v:lnum - 1)

  " #if, #else, #endif, #include
  if nonblankline =~# '^\s*#'
    return 0
  endif

  if nonblankline =~# '^\s*--'
    return match(nonblankline, '^\s*\zs--')
  endif

  if nonblankline =~# '\v^\s*}?' . noparen . '[([{]' . noparen . '[-+/*\$&<>,]?(\s*--.*)?$'
    if nonblankline =~# '\v[([{](\s*--.*)?$'
      return match(nonblankline, '\v^\s*(<where>|.*<let>)?\s*\zs') + &shiftwidth
    elseif nonblankline =~# '\v[-+/*\$&<>,](\s*--.*)?$'
      return match(nonblankline, '\v^\s*}?' . noparen . '(\[.*\|\s*\zs|[([{]\s*\zs)')
    elseif nonblankline =~# '\v^[^[\]]*\[([^[\]]*|\[[^[\]]*\])*\|([^[\]]*|\[[^[\]]*\])*(\s*--.*)?$'
      return match(nonblankline, '\v^[^[\]]*\[([^[\]]*|\[[^[\]]*\])*\zs\|')
    else
      return match(nonblankline, '\v^\s*}?' . noparen . '\zs[([{]')
    endif
  endif

  " (
  if getline(v:lnum) =~# '\v^\s*\('
    let lnum = s:prevnonblank(v:lnum - 1)
    if lnum == 0
      return -1
    elseif nonblankline =~# '\v^\s*(<where>|.*<let>).*([-+/*\$&<>=,]+|`\k+`)(\s*--.*)?$'
      return match(nonblankline, '\v^\s*(<where>|<let>)\s*\zs') + &shiftwidth
    elseif nonblankline =~# '\v^\s*(<where>|<let>)'
      return match(nonblankline, '\v^\s*(<where>|<let>)?\s*\zs')
    elseif nonblankline =~# '\v^\s*<import>'
      return indent(lnum) + &shiftwidth
    endif
  endif

  if nonblankline =~# '\v^\s*<infix[rl]?>'
    return match(nonblankline, '\S')
  endif

  if nonblankline =~# '\v^\s*<instance>.*\=\>(\s*--.*)?$'
    return match(nonblankline, '\v^\s*\zs<instance>') + &shiftwidth
  endif

  if nonblankline =~# '\v<do>(\s*--.*)?$'
    return match(nonblankline, '\v^\s*(<where>|.*<let>)?\s*\zs') + &shiftwidth
  endif

  if nonblankline =~# '\v<deriving>'
    return s:indent('', '\v^\s*\zs<data>', 0)
  endif

  if line =~# '\v<if>' && line !~# '\v^\s*#'
    if line !~# '\v<then>'
      return match(line, '\v.*<if>\s*\zs')
    elseif line !~# '\v<else>'
      return match(line, '\v.*\zs<then>')
    endif
  endif

  if line =~# '\v<case>.*<of>.*(\s*--.*)?$' && line !~# '^\s*#'
    if get(g:, 'haskell_indent_disable_case', 0)
      if line =~# '\v^\s*<where>'
        return match(line, '\v^\s*(<where>)?\s*\zs') + &shiftwidth
      else
        return indent(s:prevnonblank(v:lnum - 1)) + &shiftwidth
      endif
    else
      return line =~# '\v<case>.*<of>\s*[[:alnum:](]'
            \ ? match(line, '\v<case>.*<of>\s*\zs\S')
            \ : match(line, '\v.*<case>\s*\zs')
    endif
  endif

  if line =~# '\v\\case(\s*--.*)?$'
    return match(line, '\v^\s*(<where>|.*<let>)?\s*\zs') + &shiftwidth
  endif

  if nonblankline =~# '\v^.*[^|]\|[^|].*\='
    return s:after_guard()
  endif

  if nonblankline =~# '\v[)}\]](\s*--.*)?$'
    return s:unindent_after_parenthesis(s:prevnonblank(v:lnum - 1), match(nonblankline, '\v[)}\]](\s*--.*)?$'))
  endif

  if nonblankline =~# '\v^\s*\|\s*.*\<-\s*.*,(\s*--.*)?$'
    return match(nonblankline, '\v^\s*\|\s*\zs.*\<-\s*.*,(\s*--.*)?$')
  endif

  if nonblankline =~# '\v([-+/*\$&<>=,]+|`\k+`)(\s*--.*)?$'
    if nonblankline =~# '\v^\s*<let>.*,(\s*--.*)?$'
      return match(nonblankline, '\S')
    else
      return match(nonblankline, '\v^\s*(<where>|.*<let>)?\s*\zs') +
            \ (nonblankline =~# '\v(<where>|<let>)|^\s*\k+\s*'. noparen .'\=.*([-+/*\$&<>]|`\k+`)(\s*--.*)?$|(\=|-\>)(\s*--.*)?$' ? &shiftwidth : 0)
    endif
  endif

  if nonblankline =~# '\v<where>'
    return s:after_where()
  endif

  if nonblankline =~# '\v<module>' && nonblankline !~# '\v,(\s*--.*)?$' && indent(s:prevnonblank(v:lnum - 1)) < &shiftwidth
    return &shiftwidth
  endif

  if nonblankline =~# '\v<else>'
    let i = s:prevnonblank(v:lnum - 1)
    while i
      let line = getline(i)
      if getline(i) =~# '\v<if>'
        if getline(i) =~# '\v^\s*_\s*-\>'
          let nonblankline = getline(i)
          break
        endif
        return match(line, '\v^\s*\zs')
      endif
      let i -= 1
    endwhile
  endif

  if nonblankline =~# '\v-\>' && line =~# '\v^(\s*--.*)?$' || nonblankline =~# '\v^\s*_\s*-\>'
    let i = s:prevnonblank(v:lnum - 1)
    while i
      let line = getline(i)
      if getline(i) =~# '\v<case>'
        return match(line, '\v^\s*(where\s+)?\zs')
      endif
      let i -= 1
    endwhile
  endif

  if nonblankline =~# '\v^\s*<data>.*\='
    if nonblankline =~# '\v\{-#\s*UNPACK\s*#-}' && getline(v:lnum) =~# '\v^\s*\{-#\s*UNPACK\s*#-}'
      return match(nonblankline, '\v\{-#\s*UNPACK\s*#-}')
    endif
    return s:indent('', '\v^.*<data>.*\zs\=', 0)
  endif

  if nonblankline =~# '\v<let>\s+.*\=' && nonblankline !~# '\v<let>\s+.*\=.*<in>'
    return s:indent('', getline(v:lnum) =~# '\v^\s*(<in>|\S+\s*\=)' ? '\v<let>\s+\zs\S' : '\v<let>', 0)
  endif

  " in
  if nonblankline =~# '\v^\s*<in>'
    return s:indent('', '\v^\s*\zs.*<let>', 0, -1)
  endif

  if nonblankline =~# '::'
    return s:indent('', nonblankline =~# '\v,(\s*--.*)?$' ? '\S' : '\v\{\s*\<\w+\s*::', 0, match(nonblankline, '\S'))
  endif

  if s:prevnonblank(v:lnum - 1) < v:lnum - 2 && line !~# '^\s*#'
    return 0
  elseif s:prevnonblank(v:lnum - 1) < v:lnum - 1 && line !~# '^\s*#'
    let i = s:prevnonblank(v:lnum - 1)
    let where_clause = 0
    let found_where = 0
    let indent = indent(s:prevnonblank(v:lnum - 1))
    while i
      let line = getline(i)
      if substitute(line, '--.*', '', 'g') =~# '\v<where>'
        let found_where = 1
        if indent(i) <= indent
          let where_clause += 1
          if where_clause == v:lnum - s:prevnonblank(v:lnum - 1)
            return match(line, '\v^.*<where>\s*\zs')
          endif
        endif
      endif
      if 0 <= indent(i) && indent(i) < indent && line !~# '\v<where>|^\s*\||^$'
        return line =~# '\v^\s*[([{]' ? indent : indent(i)
      endif
      if line =~# '\v^\s*<(class|instance)>' && found_where
        return match(line, '\v^\s*<(class|instance)>') + &shiftwidth
      elseif line =~# '^\S'
        return 0
      endif
      let i -= 1
    endwhile
    return 0
  endif

  if indent(s:prevnonblank(s:prevnonblank(v:lnum - 1) - 1)) < indent(s:prevnonblank(v:lnum - 1))
        \ && nonblankline =~# '\v^\s*[-+/*$&<>=]' || getline(s:prevnonblank(s:prevnonblank(v:lnum - 1) - 1)) =~# '\v\=(\s*--.*)?$'
    return indent(s:prevnonblank(s:prevnonblank(v:lnum - 1) - 1))
  endif

  return indent(s:prevnonblank(v:lnum - 1))

endfunction

" prevnonblank with skipping macros
function! s:prevnonblank(lnum) abort
  let i = a:lnum
  while i > 0
    let i = prevnonblank(i)
    if getline(i) !~# '\v^\s*#\s*\w+'
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
  let start = searchpos('\v(--.*)@<!\{-', 'bcnW')
  let pos = getpos('.')
  let end = searchpos('-}', 'bcnW')
  return start != [0, 0] && (start[0] < pos[1] || start[0] == pos[1] && start[1] <= pos[2])
        \ && (end == [0, 0] || end[0] < start[0] || end[0] == start[0] && end[1] < start[1])
endfunction

" comment
function! s:indent_comment() abort
  if getline(s:prevnonblank(v:lnum - 1)) =~# '\v\{-#\s*UNPACK\s*#-}' && getline(v:lnum) =~# '\v^\s*\{-#\s*UNPACK\s*#-}'
    return match(getline(s:prevnonblank(v:lnum - 1)), '\v\{-#\s*UNPACK\s*#-}')
  elseif getline(v:lnum) =~# '\v^\s*\{-#\s*<RULES>(\s*--.*)?$'
    let name = matchstr(getline(v:lnum + 1), '\v^\s*"\zs\k+\ze(/\k+)*"')
    if name !=# ''
      let i = v:lnum - 1
      while i
        if getline(i) =~# '\v^\s*(where\s+)?<' . name . '>.*\='
          return match(getline(i), '\v^\s*(<where>)?\s*\zs')
        endif
        let i -= 1
      endwhile
    endif
  endif
  if getline(v:lnum) =~# '\v^\s*\{-#\s*<(INLINE|RULES)>'
    return -1
  elseif getline(v:lnum) =~# '\v^\s*(\{- \||\{-#.*#-}(\s*--.*)?$|-- -{10,})'
    return 0
  endif
  if getline(v:lnum) =~# '^\s*[-{]-'
    let i = v:lnum
    if getline(i) =~# '^\s*--'
      while i <= line('$') && (getline(i) =~# '^\s*--' || getline(i) ==# '')
        let i += 1
      endwhile
      if getline(i) =~# '\v^\s*<(class|instance|data)>|::.*(-\>|-- *\^)'
        return match(getline(i), '^\s*\zs\S')
      endif
    endif
    let i = s:prevnonblank(v:lnum - 1)
    let previndent = 0
    while i > 0
      let line = getline(i)
      let indent = indent(i)
      if line =~# '^\s*[-{]-'
        return indent
      elseif line =~# '\v^\s*<(class|instance)>|^\s*<where>(\s*--.*)?$' && line !~# '\v,(\s*--.*)?$'
        return indent + &shiftwidth
      elseif line =~# '\v\s*\((\s*--.*)?$'
        return previndent ? previndent : indent + &shiftwidth
      elseif line =~# '^\S' && line !~# '^\s*#'
        return 0
      endif
      let previndent = indent
      let i -= 1
    endwhile
  endif
  let listpattern = '\v^\s*(\* \@|[a-z]\)\s+|\>\s+)'
  if getline(v:lnum) =~# listpattern
    if getline(s:prevnonblank(v:lnum - 1)) =~# listpattern
      return indent(s:prevnonblank(v:lnum - 1))
    else
      if getline(v:lnum) =~# '\v^\s*[a-z]\)\s+'
        let i = s:prevnonblank(v:lnum - 1)
        let indent = indent(i)
        while 0 < i && indent(i) == indent
          let i -= 1
        endwhile
        if 0 < i && getline(i) =~# '\v^\s*[a-z]\)\s+'
          return indent(i)
        endif
      endif
      return indent(s:prevnonblank(v:lnum - 1)) + &shiftwidth
    endif
  endif
  if getline(v:lnum - 1) =~# '\v^\s*[a-z]\)\s+'
    return match(getline(v:lnum - 1), '\v^\s*[a-z]\)\s+\zs')
  endif
  if getline(v:lnum) !~# '\v^(\s*--.*)?$' && getline(s:prevnonblank(v:lnum - 1)) =~# listpattern
    return indent(s:prevnonblank(v:lnum - 1)) - &shiftwidth
  endif
  if getline(v:lnum) =~# '^\s*[-{]-'
    return 0
  endif
  let line = getline(s:prevnonblank(v:lnum - 1))
  if line =~# '\v^\s*\{-#\s*(\s+\w+,?)+'
    if line =~# '\v,(\s*--.*)?$'
      return match(line, '\v\zs<\w+,')
    else
      return match(line, '\v\w+\s+\zs<\w+') - &shiftwidth
    endif
  endif
  let i = s:prevnonblank(v:lnum - 1)
  if i < v:lnum - 1
    let indent = indent(i)
    while 0 < i && indent(i) == indent
      let i -= 1
    endwhile
    if 0 < i && getline(i) =~# '\v^\s*[a-z]\)\s+'
      return indent(i) - &shiftwidth
    endif
  endif
  if getline(v:lnum) =~# '\v^\s*(#?-}|#$)'
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

" else
function! s:indent_else() abort
  let i = s:prevnonblank(v:lnum - 1)
  while i > 0
    let line = getline(i)
    if line =~# '\v<then>'
      return match(line, '\v<then>')
    endif
    let i = s:prevnonblank(i - 1)
  endwhile
endfunction

" |
function! s:indent_bar() abort
  if getline(v:lnum) !~# '^\s*|'
    return -1
  endif
  let i = s:prevnonblank(v:lnum - 1)
  let indent = indent(i)
  while i > 0
    let line = getline(i)
    if line =~# '\v^[^[\]]*([^[\]]*|\[[^[\]]*\])*\[([^[\]]*|\[[^[\]]*\])*(--.*)?$'
      return match(line, '\v^[^[\]]*([^[\]]*|\[[^[\]]*\])*\zs\[([^[\]]*|\[[^[\]]*\])*(--.*)?$') + &shiftwidth
    elseif line =~# '\v^\s*(<where>)?.*[^|]\|[^|].*\='
      return match(line, '\v^\s*(<where>)?.*[^|]\zs\|[^|].*\=')
    elseif line =~# '\v<data>.*\='
      return match(line, '\v^.*<data>.*\zs\=')
    elseif line =~# '\v^\s*<where>(\s*--.*)?$' && indent(i) < indent || line =~# '^\S'
      return indent + &shiftwidth
    elseif line =~# '\v^\s*<where>\s+\S'
      return match(line, '\v^\s*<where>\s+\zs\S') + &shiftwidth
    elseif line =~# '\v[^|]\|[^|].*-\>'
      return match(line, '\v[^|]\zs\|[^|].*-\>')
    elseif line =~# '^\s*='
      return match(line, '^\s*\zs=')
    endif
    let indent = indent(i)
    let i = s:prevnonblank(i - 1)
  endwhile
endfunction

" guard
function! s:after_guard() abort
  let nonblankline = getline(s:prevnonblank(v:lnum - 1))
  let line = getline(v:lnum - 1)
  if line =~# '\v^(\s*--.*)?$'
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
      if where_clause && line !~# '\v^(\s*--.*)?$' && line !~# '\v^\s*\|[^|]'
        return match(line, '\v^\s*(<where>)?\s*\zs')
      endif
      if line =~# '\v<where>'
        let where_clause = 1
      endif
      let i -= 1
    endwhile
  endif
  if nonblankline =~# '\v[^|]\|\s*(otherwise|True|0\s*\<\s*1|1\s*\>\s*0)' || getline(v:lnum) =~# '^\s*\S'
    let i = s:prevnonblank(v:lnum - 1)
    while i
      let line = getline(i)
      if line !~# '\v^(\s*--.*)?$' && line !~# '^\s*|'
        return match(line, '\v^\s*(<where>)?\s*\zs')
      endif
      let i -= 1
    endwhile
  elseif nonblankline =~# '\v^\s*<data>.*\='
    return match(line, '\v^.*<data>.*\zs\=')
  else
    return match(line, '\v^.*[^|]\zs\|[^|].*\=')
  endif
endfunction

" =
function! s:indent_eq() abort
  return match(getline(s:prevnonblank(v:lnum - 1)), '\v^\s*(<where>|<let>)?\s*\zs') + &shiftwidth
endfunction

" }, ], )
function! s:indent_parenthesis() abort
  let view = winsaveview()
  execute 'normal! ' v:lnum . 'gg^'
  let end = getpos('.')
  normal! %
  let begin = getpos('.')
  call setpos('.', end)
  call winrestview(view)
  if begin[1] == end[1]
    return -1
  endif
  if indent(end[1] - 1) + 1 < begin[2]
    return match(getline(begin[1]), '\v^\s*(<where>|.*<let>)?\s*\zs')
  endif
  if getline(end[1]) =~# '^\s*}' && getline(begin[1]) =~# '\v^\s+\w+\s*\{'
    return match(getline(begin[1]), '\v^\s+\zs')
  endif
  return begin[2] - 1
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
  if getline(begin[1]) =~# '\v<deriving>'
    let i = begin[1]
    while i
      let line = getline(i)
      if getline(i) =~# '\v<data>'
        return match(line, '\v<data>')
      elseif line =~# '^\S'
        return -1
      endif
      let i -= 1
    endwhile
  elseif getline(begin[1]) =~# '^\s*='
    return match(getline(s:prevnonblank(begin[1] - 1)), '\v^\s*(<where>|<let>)?\s*\zs')
  elseif getline(s:prevnonblank(begin[1] - 1)) =~# '\v\=(\s*--.*)?$'
    return match(getline(s:prevnonblank(begin[1] - 1)), '\v^\s*(<where>|<let>)?\s*\zs')
  elseif getline(s:prevnonblank(begin[1] - 1)) =~# '\v<import>'
    return 0
  endif
  return match(getline(begin[1]), '\v^\s*(<where>)?\s*\zs')
endfunction

" where
function! s:indent_where() abort
  if getline(v:lnum) =~# '\v^\s*<wher%[e]>'
    let i = s:prevnonblank(v:lnum - 1)
    while i > 0
      let line = getline(i)
      if line =~# '\v^\s*(<where>)?\s*\zs\h.*\=|^\s*[^| ]'
        return match(line, '\v^\s*(<where>)?\s*\zs\h.*\=|^\s*[^| ]') + &shiftwidth
      elseif line =~# '^\S'
        return -1
      endif
      let i -= 1
    endwhile
  elseif getline(v:lnum) =~# '\v^\s*\)\s*<wher%[e]>'
    let pos = getpos('.')
    let view = winsaveview()
    execute 'normal! ' (match(getline(v:lnum), ')') + 1)  . '|%'
    let begin = getpos('.')
    call setpos('.', pos)
    call winrestview(view)
    if getline(begin[1]) =~# '\v(<module>|<class>|<instance>)'
      return indent(begin[1]) + &shiftwidth
    elseif getline(s:prevnonblank(begin[1] - 1)) =~# '\v(<module>|<class>|<instance>)'
      return indent(s:prevnonblank(begin[1] - 1)) + &shiftwidth
    elseif getline(begin[1]) =~# '\v^\s*\((--.*)?'
      return indent(begin[1])
    endif
  elseif getline(v:lnum) =~# '\v^\s*(<module>|<class>|<instance>)'
    return 0
  elseif getline(v:lnum) =~# '\v<where>\s*(--.*)?'
    let i = s:prevnonblank(v:lnum - 1)
    if i > 0
      let line = getline(i)
      if line =~# '\v^\s*(<module>|<class>|<instance>)'
        return indent(i) + &shiftwidth
      endif
    endif
  endif
  return -1
endfunction

" where
function! s:after_where() abort
  let line = getline(s:prevnonblank(v:lnum - 1))
  if line =~# '\v^\s*\)\s*<where>(\s*--.*)?$'
    let pos = getpos('.')
    let view = winsaveview()
    execute 'normal! ' s:prevnonblank(v:lnum - 1) . 'gg^%'
    let begin = getpos('.')
    call setpos('.', pos)
    call winrestview(view)
    let i = getline(begin[1]) =~# '^\s*(' ? s:prevnonblank(begin[1] - 1) : begin[1]
    if i > 0 && getline(i) =~# '\v(<module>|<class>|<instance>)'
      return 0
    endif
  endif
  if line =~# '\v<where>(\s*--.*)?$'
    let i = s:prevnonblank(v:lnum - 1)
    while i > 0
      let line = getline(i)
      if line =~# '\v^\s*<module>'
        return 0
      elseif line =~# '\v^\s*(<class>|<instance>|<data>|<type> +<family>)'
        if line =~# '\v<where>(\s*--.*)?$' && i != s:prevnonblank(v:lnum - 1)
          break
        endif
        return match(line, '\v(<class>|<instance>|<data>|<type> +<family>)') + &shiftwidth
      elseif line =~# '\v^(\S|\s*\k+\s*\=)' && line !~# '^--'
        return match(getline(s:prevnonblank(v:lnum - 1)), '\v<where>') + &shiftwidth
      endif
      let i -= 1
    endwhile
  endif
  if line =~# '\v^\s*<where>'
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
          return match(line, '\v^\s*(<where>)?\s*\zs')
        endif
        let i -= 1
      endwhile
      return 0
    endif
    return match(line, '\v<where>\s*\zs')
  endif
  if getline(s:prevnonblank(v:lnum - 1)) =~# '\v^\s*<where>(\s*--.*)?$'
    return indent(s:prevnonblank(v:lnum - 1)) + &shiftwidth
  endif
  return indent(s:prevnonblank(v:lnum - 1))
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
