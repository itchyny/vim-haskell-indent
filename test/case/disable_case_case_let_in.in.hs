<ESC>:let g:haskell_indent_disable_case = 1
ah = f
where
f x = case x of
1 -> let y = g x
in y
4 -> let y = g x
in y
_ -> let y = g x
in y
