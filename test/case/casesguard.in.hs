filter = \cases _ []                 -> []
p (x:xs) | p x       -> x : filter p xs
| otherwise ->     filter p xs
