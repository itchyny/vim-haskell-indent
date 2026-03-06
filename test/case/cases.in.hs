printColor :: Shade -> Color -> Text
printColor = \cases
Light Red   -> "light red"
Light Blue  -> "light blue"
Dark  Red   -> "dark red"
Dark  Blue  -> "dark blue"
