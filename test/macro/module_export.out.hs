module X (
  foo,
#if __GLASGOW_HASKELL__
  bar,
#endif
#if __GLASGOW_HASKELL__ >= 708
  baz
#endif
  ) where
