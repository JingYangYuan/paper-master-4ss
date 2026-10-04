## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

# we preload it to avoid ugly (was comiled with R.x.x) warnings in the doc
library(stringmagic)

# Option to allow caching in non interactive mode
options("string_magic_string_get_forced_caching" = TRUE)

## -----------------------------------------------------------------------------
cars = row.names(mtcars)
cat_magic("All cars from mtcars:\n{C, 60 swidth ? cars}")

# cars with an 'a', an 'e', an 'i', and an 'o', all in lower case
string_get(cars, "a & e & i & o")

# cars with no 'e' and at least one digit
string_get(cars, "!e & \\d")

# flags apply to all
# contains the 'words' 2, 9 or l
# alternative syntax for flags: "wi/2 | 9 | l"
string_get(cars, "word, ignore/2 | 9 | l")

## -----------------------------------------------------------------------------
# string_get(cars, "a & e & i & o")
# cars with an 'a', an 'e', an 'i', and an 'o', all in lower case
string_get(cars, "a", "e", "i", "o")

# string_get(cars, "!e & \\d")
# cars with no 'e' and at least one digit
string_get(cars, "!e", "\\d")

# string_get(cars, "!/e & \\d")
# This example cannot be replicated directly, we need to apply logical equivalence
string_get(cars, "!e", "!\\d", or = TRUE)

# string_get(cars, "wi/2 | 9 | l")
# contains the 'words' 2, 9 or l
string_get(cars, "2", "9", "l", or = TRUE, word = TRUE, ignore.case = TRUE)

## -----------------------------------------------------------------------------
# cars without digits, then cars with 2 'a's or 2 'e's and a digit
string_get(cars, "!\\d", "i/a.+a | e.+e & \\d", seq = TRUE)

# let's get the first word of each car name
car_first = string_ops(cars, "extract.first")
# we select car brands ending with 'a', then ending with 'i'
string_get(car_first, "a$", "i$", seq = TRUE)
# seq.unik is similar to seq but applies unique()
string_get(car_first, "a$", "i$", seq.unik = TRUE)

## -----------------------------------------------------------------------------
# Since we used `car_first` in the previous example, we don't need to provide
# it explicitly now
# => brands containing 'M' and ending with 'a' or 'i'; brands containing 'M'
string_get("M & [ai]$", "M", seq.unik = TRUE)

## -----------------------------------------------------------------------------
# parsing an input: extracting the numbers
input = "8.5in, 5.5, .5 cm"
string_ops(input, "','split, tws, '^\\. => 0.'replace, '^\\D+|\\D+$'replace, num")


# Explanation------------------------------------------------------------------|
# ','split: splitting w.r.t. ','                                               |
# tws: trimming the whitespaces                                                |
# '^\\. => 0.'replace: adds a 0 to strings starting with '.'                   |
# '^\\D+|\\D+$'replace: removes non-digits on both ends of the string          |
# num: converts to numeric                                                     |


# now extracting the units
string_ops(input, "','split, '^[ \\d.]+'replace, tws")


# Explanation------------------------------------------------------------------|
# ','split: splitting w.r.t. ','                                               |
# '^[ \\d.]+'replace: removes the ' ', digit                                   |
#                     and '.' at the beginning of the string                   |
# tws: trimming the whitespaces                                                |

## -----------------------------------------------------------------------------
# Now using the car data
cars = row.names(mtcars)

# let's get the brands starting with an "m"
string_ops(cars, "'i/^m'get, x, unik")


# Explanation------------------------------------------------------------------|
# 'i/^m'get: keeps only the elements starting with an m,                       |
#            i/ is the 'regex-flag' "ignore" to ignore the case                |
#            ^m means "starts with an m" in regex language                     |
# x: extracts the first pattern. The default pattern is "[[:alnum:]]+"         |
#    which means an alpha-numeric word                                         |
# unik: applies unique() to the vector                                         |


# let's get the 3 largest numbers appearing in the car models
string_ops(cars, "'\\d+'x, rm, unik, num, dsort, 3 first")


# Explanation------------------------------------------------------------------|
# '\\d+'x: extracts the first pattern, the pattern meaning "a succession"      |
#          of digits in regex language                                         |
# rm: removes elements equal to the empty string (default behavior)            |
# unik: applies unique() to the vector                                         |
# num: converts to numeric                                                     |
# dsort: sorts in decreasing order                                             |
# 3 first: keeps only the first three element                                  |

## -----------------------------------------------------------------------------
monologue = c("For who would bear the whips and scorns of time",
              "Th' oppressor's wrong, the proud man's contumely,",
              "The pangs of despis'd love, the law's delay,",
              "The insolence of office, and the spurns",
              "That patient merit of th' unworthy takes,",
              "When he himself might his quietus make",
              "With a bare bodkin? Who would these fardels bear,",
              "To grunt and sweat under a weary life,",
              "But that the dread of something after death-",
              "The undiscover'd country, from whose bourn",
              "No traveller returns- puzzles the will,",
              "And makes us rather bear those ills we have",
              "Than fly to others that we know not of?")

# Cleaning a text
string_clean(monologue, 
          # use string_magic to: lower the case and remove basic stopwords
          "@lower, stopword",
          # remove a few extra stopwords(we use the flag word 'w/')
          "w/th, 's",
          # manually stem some verbs
          "despis'd => despise", "undiscover'd => undiscover", "(m|t)akes => \\1ake",
          # still stemming: dropping the ending 's' for words of 4+ letters, except for quietus
          "(\\w{3,}[^u])s\\b => \\1",
          # normalizing the whitespaces + removing punctuation
          "@ws.punct")


## -----------------------------------------------------------------------------
fruits = string_vec("orange, apple, pineapple, strawberry")
fruits

## -----------------------------------------------------------------------------
more_fruits = string_vec("lemon, {fruits}, peach")
more_fruits

## -----------------------------------------------------------------------------
more_fruits = string_vec("lemon, {6 Shorten ? fruits}, peach")
more_fruits

## -----------------------------------------------------------------------------
pkgs = string_vec("pandas, os, time, re")
imports = string_vec("import numpy as np, import {pkgs}")
imports

## -----------------------------------------------------------------------------
string_vec("1, 5,
            3, 2,
            5, 12", .nmat = TRUE)

## -----------------------------------------------------------------------------
string_vec(1, 5,
           3, 2,
           5, 12, .nmat = 3)

## -----------------------------------------------------------------------------
# you can add the column names directly in the argument .df
df = string_vec("1, john,
                 3, marie,
                 5, harry", .df = "id, name")
df

# automatic conversion of numeric values
df$id * 5

## -----------------------------------------------------------------------------
x = c("Nor rain, wind, thunder, fire are my daughters.",
      "When my information changes, I alter my conclusions.")

# we split at each word
sentences_split = string_split2df(x, "[[:punct:] ]+")
sentences_split

# recovering the original vectors (we only lose the punctuation)
paste_conditional(sentences_split$x, sentences_split$obs)

## -----------------------------------------------------------------------------
id = c("ws", "jmk")
# we add the identifier
base_words = string_split2df(x, "[[:punct:] ]+", id = list(author = id))

# merging back using a formula
paste_conditional(x ~ author, base_words)

