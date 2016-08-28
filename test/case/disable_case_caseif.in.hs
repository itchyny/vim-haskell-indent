<ESC>:let g:haskell_indent_disable_case = 1
ah x = x
where
f x = case x of
1 -> if g x
then 2
else 3
4 -> if g x
then 5
else 6
_ -> if g x
then 7
else 8
g x = False
