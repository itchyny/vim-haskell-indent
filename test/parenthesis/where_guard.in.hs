g = f
where f x | x > 10 = [ y | y <- [s..x] ]
| otherwise = []
s = 0
