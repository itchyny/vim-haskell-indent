let s:assert = themis#helper('assert')

function! s:before()
  filetype plugin indent on
  setlocal filetype=haskell
  setlocal formatoptions-=cro
endfunction

function! s:before_each()
  % delete _
  setlocal expandtab shiftwidth=2
  let g:haskell_indent_disable_case = 0
endfunction

function! s:test(path)
  for path in filter(split(glob(a:path . '/*')), 'isdirectory(v:val)')
    let suite = themis#suite('Test for ' . matchstr(path, '\w*$'))
    let suite.before = function('s:before')
    let suite.before_each = function('s:before_each')
    for infile in split(glob(path . '/*.in.hs', 1), "\n")
      execute join([
            \ 'function! suite.' . matchstr(infile, '\w*\ze\.in\.hs$') . '()'
            \,'  let infile = ' . string(infile)
            \,'  let result = ' . string(substitute(infile, '\.\zsin\ze\.hs$', 'out', ''))
            \,'  execute "normal! i" . substitute(join(readfile(infile), "<CR>"),'
            \.'          ''<\a*>'', ''\=eval(''''"\''''.submatch(0).''''"'''')'', ''g'')'
            \,'  call s:assert.equals(getline(1, line("$")), readfile(result))'
            \,'  normal! ggvG100<gv='
            \,'  call s:assert.equals(getline(1, line("$")), readfile(result))'
            \,'  normal! gg=G'
            \,'  call s:assert.equals(getline(1, line("$")), readfile(result))'
            \,'  %s/\S\zs$/ -- XXX/'
            \,'  normal! ggvG100<gv='
            \,'  %s/\s* -- XXX$//'
            \,'  call s:assert.equals(getline(1, line("$")), readfile(result))'
            \,'endfunction' ], "\n")
    endfor
  endfor
endfunction

call s:test(expand('<sfile>:p:h'))
