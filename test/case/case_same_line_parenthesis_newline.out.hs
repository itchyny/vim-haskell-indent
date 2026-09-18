f x = (case x of 1 -> 0
                 2 -> 1
                 )
g = f 3 (case x of -1 -> 0
                   2 -> 1
                   )
h = 0
