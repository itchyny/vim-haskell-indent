module X (
-- foo
foo,
#if __GLASGOW_HASKELL__
-- bar
bar,
#endif
#if __GLASGOW_HASKELL__ >= 708
-- baz
baz
#endif
) where
