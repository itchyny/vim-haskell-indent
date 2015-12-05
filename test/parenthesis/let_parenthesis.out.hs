f = do
  let x = Foo { foo: 1,
                bar: 2 }
  y <- return 0
  return (x, y)
