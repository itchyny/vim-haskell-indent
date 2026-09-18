parseDef :: Parser Def
parseDef = do char '!'
              name <- identifier
              char '('
              hello

f = do g "a(b"
       h
       i

j = foldl' '(' x
k
