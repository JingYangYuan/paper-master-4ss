## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

library(stringmagic)

## -----------------------------------------------------------------------------
cars = row.names(mtcars)
print(cars)

# which one...
# ... contains all letters 'a', 'e', 'i' AND 'o'?
string_get(cars, "a & e & i & o")

# ... does NOT contain any digit?
string_get(cars, "!\\d")

