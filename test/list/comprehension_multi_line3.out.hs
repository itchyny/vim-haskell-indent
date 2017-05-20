z = (x, y)
  where x = [ n * n
              | n <- ns,
                odd n,
                isPrime n ]
        y = [ n * n | n <- [1..],
                      even n,
                      let z = n,
                      isPrime (z `div` 2) ]
