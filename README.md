# vim-haskell-indent [![CI Status](https://github.com/itchyny/vim-haskell-indent/workflows/CI/badge.svg)](https://github.com/itchyny/vim-haskell-indent/actions)
## The best indent plugin for Haskell in Vim

![vim-haskell-indent](https://raw.githubusercontent.com/wiki/itchyny/vim-haskell-indent/image/1.gif)

![vim-haskell-indent](https://raw.githubusercontent.com/wiki/itchyny/vim-haskell-indent/image/2.gif)

![vim-haskell-indent](https://raw.githubusercontent.com/wiki/itchyny/vim-haskell-indent/image/3.gif)

## Installation
Install with your favorite plugin manager.

## Options
If you don't like the default indentation you can easily change it by creating the following variables.

Here are some examples:

* `let g:haskell_indent_do = 3`
  
      do
      >>>foo
  
* `let g:haskell_indent_if = 2`
  
      if foo
      >>then bar
      >>else baz

* `let g:haskell_indent_case = 2`
  
      case foo of
      >>bar -> baz

* `let g:haskell_indent_in = 1`

      let x = 1
      >in x

## Author
itchyny (https://github.com/itchyny)

## License
This software is released under the MIT License, see LICENSE.
