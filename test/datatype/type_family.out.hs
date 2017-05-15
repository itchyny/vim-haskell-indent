class X k => G k where
  data GM k :: * -> *
  a :: GM k v

instance X Int where
  data GM Int v = GMI (Map.Map Int v)
  a = GMI Map.empty

instance X Char where
  data GM Char v = GMI (Map.Map Char v)
  a = GMI Map.empty

class Y y where
  type E e
  z :: e

instance Y Int where
  type E = Int
  z = 0
