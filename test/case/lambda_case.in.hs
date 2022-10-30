f = \case
1 -> 0
2 -> 1
x -> g x
where g = \case
x -> x
