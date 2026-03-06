multi_if :: Int
multi_if = if | e -> 1
| o -> 3

handle :: IOError -> IO ()
handle e = putStrLn $ if | isAlreadyExistsError e -> "File already exists"
| isDoesNotExistError e -> "File does not exist"
| isEOFError e -> "Reached EOF"
| isPermissionError e -> "File access denied"
