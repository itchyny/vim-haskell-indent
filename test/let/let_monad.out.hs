f = do
  let x = 0
  y <- return 0
  let z = 0
  w <- return 0
  return (x, y, z, w)
