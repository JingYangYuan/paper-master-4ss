## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

library(stringmagic)

## -----------------------------------------------------------------------------
code = c("DT = as.data.table(iris)", 
         "DT[, .(pl_sl = string_magic('PL/SL = {Petal.Length / Sepal.Length}')]")

string_get(code, "if/dt[")

## -----------------------------------------------------------------------------
unhappy = "Rumble thy bellyful! Spit, fire! spout, rain!
Nor rain, wind, thunder, fire are my daughters.
I tax not you, you elements, with unkindness.
I never gave you kingdom, call'd you children,
You owe me no subscription. Then let fall
Your horrible pleasure. Here I stand your slave,
A poor, infirm, weak, and despis'd old man."

# the ignore flag allows to retain words starting with the
# upper cased letters
# ex: getting words starting with the letter 'r' to 'z'
cat_magic("{'ignore/\\b[r-z]\\w+'extract, c, 60 swidth ? unhappy}")

## -----------------------------------------------------------------------------
x = "50 + 5 * 5 = 40"
string_clean(x, "f/+", "f/*", replacement = "-")

# Without the fixed flag, we would have gotten an error since '+' or '*'
# have a special meaning in regular expressions (it is a quantifier)
# and expects something before

# Here's the error
try(string_clean(x, "+", "*", replacement = "-"))

## -----------------------------------------------------------------------------
le_mont_des_oliviers = "S'il est vrai qu'au Jardin sacré des Écritures,
Le Fils de l'homme ai dit ce qu'on voit rapporté ;
Muet, aveugle et sourd au cri des créatures,
Si le Ciel nous laissa comme un monde avorté,
Alors le Juste opposera le dédain à l'absence
Et ne répondra plus que par un froid silence
Au silence éternel de la Divinité."

# we hide a few words from this poem
string_magic("{'wi/et, le, il, au, des?, ce => _'replace ? le_mont_des_oliviers}")

## -----------------------------------------------------------------------------
vowels ="aeiouy"
# let's keep only the vowels
# we want the pattern: "[^aeiouy]"
lmb = "'Tis safer to be that which we destroy
Than by destruction dwell in doubtful joy."
string_replace(lmb, "magic/[^{vowels}]", "_")

#
# Illustration of `string_magic` operations before regex application
#

cars = row.names(mtcars)
# Which of these models contain a digit?
models = c("Toyota", "Hornet", "Porsche")
# we want the pattern "(Toyota|Hornet|"Porsche).+\\d"
# we collapse the models with a pipe using '|'c
string_get(cars, "m/({'|'c ? models}).+\\d")

# alternative: same as above but we first comma-split the vector
models_comma = "Toyota, Hornet, Porsche"
string_get(cars, "m/({S, '|'c ? models_comma}).+\\d")

#
# Interpolation does not apply to regex-specific curly brackets
#

# We delete only successions of 2+ vowels
# {2,} has a rexex meaning and is not interpolated:
string_replace(lmb, "magic/[{vowels}]{2,}", "_")

## -----------------------------------------------------------------------------
cars_small = head(row.names(mtcars))
print(cars_small)

string_replace(cars_small, "ti/mazda", "Mazda: sold out!")

## -----------------------------------------------------------------------------
cars_small = head(row.names(mtcars))
print(cars_small)

string_replace(cars_small, "total, ignore/\\d & !e", "I don't like that brand!")

## -----------------------------------------------------------------------------
encounter = string_vec("Hi Cyclops., Hi you. What's your name?, Odysseus is my name.")
# we only remove the first word
string_replace(encounter, "single/\\w+", "...")

## -----------------------------------------------------------------------------
eq = "5/x = 3/2"
# escaping with backslashes
string_replace(eq, "(\\w)\\/(\\w)", "\\2/\\1")

## -----------------------------------------------------------------------------
path = "my/path/to/the/file.tex"
# we keep the directory only

# first try: an error bc flags are expected before the first '/'
try(string_replace(path, "/[^/]+$"))

# after escaping: works (only the first slash requires escaping)
string_replace(path, "\\/[^/]+$")

# if we did add a flag, we would need to double the slash
# compare...
string_replace(path, "i//[^/]+$")
# to...
string_replace(path, "i/[^/]+$")

