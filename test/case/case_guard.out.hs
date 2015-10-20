f x | x < 10 = case x of
                    1 -> 1
                    2 -> 0
                    _ -> x
    | otherwise = case x of
                       10 -> 1
                       20 -> 0
                       _ -> x
