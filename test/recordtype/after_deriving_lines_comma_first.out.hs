data X = X { foo :: Int,
             bar :: String
           } deriving ( Eq
                      , Ord
                      , Show )
f x = x
