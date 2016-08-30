f x = case x of
           1 -> 0
           y | y < 10 -> 10 - y
             | otherwise -> y
