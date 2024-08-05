printGender :: Language -> Gender -> Text
printGender = \cases
English Male   -> "Male"
English Female -> "Female"
Chinese Male   -> "男性"
Chinese Female -> "女性"
