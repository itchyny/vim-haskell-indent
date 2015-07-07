g = f
where
f y@(x:xs) | x > 10 = let z = [] in (z)
| otherwise = []
