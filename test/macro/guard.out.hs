f = g
  where
#ifdef X
    g _ _ = 1
#else
    g p x
      | p x        = 2
      | otherwise  = 3
#endif
