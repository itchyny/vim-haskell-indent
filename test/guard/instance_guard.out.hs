instance X Y where
  f (X x) (Y y)
    | g x = x
    | otherwise = y
  g = h
