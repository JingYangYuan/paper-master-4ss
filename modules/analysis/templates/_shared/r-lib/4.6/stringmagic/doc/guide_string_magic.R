## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

# we preload it to avoid ugly (was compiled with R.x.x) warnings in the doc
library(stringmagic)

## -----------------------------------------------------------------------------
library(stringmagic)
x = "John" ; y = "Mary"
string_magic("Hi {x}! How's {y} doing?")

## -----------------------------------------------------------------------------
string_magic("Hi {x}! How's {y} doing?", y = "Jane")

## -----------------------------------------------------------------------------
lovers = c("romeo", "juliet")
string_magic("Famous lovers: {title, enum ? lovers}.")

## -----------------------------------------------------------------------------
string_magic("The max of each variable is: {enum ? sapply(iris[, 1:4], max)}.")

## -----------------------------------------------------------------------------
email = "John@Doe.com"
string_magic("This message comes from {'@'split, first ? email}.")

## -----------------------------------------------------------------------------
string_magic("The first two species are: {unik, '2'first, q, enum ? iris$Species}.")

## -----------------------------------------------------------------------------
string_magic("The first five sepal lengths are: {5 first, enum ? iris$Sepal.Length}.")

## -----------------------------------------------------------------------------
n = 5
string_magic("The first {N?n} sepal lengths are: {`n`first, enum ? iris$Sepal.Length}.")

## -----------------------------------------------------------------------------
fields = c("maths", "physics")
string_magic("This position requires a PhD in either: {enum.i.or ? fields}.")

## -----------------------------------------------------------------------------
oversight = "hey, you forgot. forgot what? forgot the capital letters!"
string_magic("{upper.sentence ? oversight}")

## -----------------------------------------------------------------------------
string_magic("Hello {upper ! world}.")

## -----------------------------------------------------------------------------
string_magic("y = {' + 'collapse ! x{1:3}}")

## -----------------------------------------------------------------------------
n = 2
string_magic("poly({n}): {' + 'collapse ! {letters[1 + 0:n]}x^{0:n}}")

## -----------------------------------------------------------------------------
n = 4
string_magic("poly({n}): {' + 'c, 'f/x^0, ^1'clean ! {letters[1 + 0:n]}x^{0:n}}")

## -----------------------------------------------------------------------------
friends = c("Piglet", "Eeyore")
string_magic("My best friend{$s, are, enum ? friends}. Who am I?")

friends = "Mercutio"
string_magic("My best friend{$s, are, enum ? friends}. Who am I?")

## -----------------------------------------------------------------------------
nFiles = 6
string_magic("Warning: {N?nFiles} file{#s, is} corrupted.")

nFiles = 1
string_magic("Warning: {N?nFiles} file{#s, is} corrupted.")

## -----------------------------------------------------------------------------
# Here opening delimiter is escaped: the closing delimiter has no special meaning
string_magic("open = \\{, close = }")

## -----------------------------------------------------------------------------
string_magic("Here are closing brackets: {5 times.c ! \\}}")

## -----------------------------------------------------------------------------
string_magic("Here I {interpolate} with .[this] ", .delim = ".[ ]", this = ".[]")

## -----------------------------------------------------------------------------
string_magic("Here I {interpolate} with \\.[] ", .delim = ".[ ]")

# another example with {{ }}  as delimiter
string_magic("I {{what}} with \\{{ }} ", .delim = "{{ }}", what = "interpolate")

## -----------------------------------------------------------------------------
string_magic("I {'can {write} {{what}} I want'}")

## -----------------------------------------------------------------------------
# if-else statement with semi-colon
is_c = TRUE
string_magic("{&is_c ; int i = 1\\; ; i = 1}")

is_c = FALSE
string_magic("{&is_c ; int i = 1\\; ; i = 1}")

## -----------------------------------------------------------------------------
string_magic("{!TRUE} is {?!TRUE}")

