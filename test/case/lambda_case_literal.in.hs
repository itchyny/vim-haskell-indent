f = \case [] -> 0
"one" -> 1
'0':_ -> 0
xs@('-':_) -> g $ read xs
where g = \case -1 -> -100
_ -> -1
