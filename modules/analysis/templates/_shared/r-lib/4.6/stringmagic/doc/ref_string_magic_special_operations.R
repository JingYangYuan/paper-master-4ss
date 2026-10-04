## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

library(stringmagic)

## -----------------------------------------------------------------------------
x = c("Oreste, Hermione", "Hermione, Pyrrhus", "Pyrrhus, Andromaque")
string_magic("Troubles ahead: {', 'split, ~(' loves 'collapse), enum ? x}.")

## -----------------------------------------------------------------------------
x = "Songe Céphise à cette nuit cruelle qui fut pour tout un peuple une nuit éternelle"
string_magic("{' 'split, if(.nchar<=4 ; nuke ; 7 shorten), collapse ? x}")

## -----------------------------------------------------------------------------
# same expression for two values of x give different results
x_short = string_magic("x{1:4}")
# the false statement is missing: it means that nothing is done is .N<=4
string_magic("y = {if(.N>4 ; 3 first, '...'insert.right), ' + 'c ? x_short}")

x_long = string_magic("x{1:10}")
string_magic("y = {if(.N>4 ; 3 first, '...'insert.right), ' + 'c ? x_long}")

## -----------------------------------------------------------------------------
pval = c(1e-20, 0.15, 0.5)
cat_magic("pvalues: {vif(.<1e-16 ; <1e-16 ; {%05f ? .}), align.right ? pval}", 
          .sep = "\n")

## -----------------------------------------------------------------------------
x = string_magic("x{1:10}")
string_magic("y = {vif(.N>4 ; {first?x} + ... + {last?x} ; {' + 'c ? x}) ? x}")

## -----------------------------------------------------------------------------
x = 1:5
string_magic("x is {&len(x)<10 ; short ; {`log10(.N)-1`times, ''c ! very }long}")

x = 1:50
string_magic("x is {&len(x)<10 ; short ; {`log10(.N)-1`times, ''c ! very }long}")

x = 1:5000
string_magic("x is {&len(x)<10 ; short ; {`log10(.N)-1`times, ''c ! very }long}")

## -----------------------------------------------------------------------------
x = 1:4
y = letters[1:4]
string_magic("{&x %% 2 ; odd ; {y}}")

## -----------------------------------------------------------------------------
i = 3 
string_magic("i = {&&i == 3 ; three}")

i = 5
string_magic("i = {&&i == 3 ; three}")

## -----------------------------------------------------------------------------
x = 5
string_magic("I bought {N?x} book{#s}.")

x = 1
string_magic("I bought {N?x} book{#s}.")

## -----------------------------------------------------------------------------
x = c("J.", "M.")
string_magic("My BFF{$s, are} {enum?x}!")

x = "J."
string_magic("My BFF{$s, are} {enum?x}!")

## -----------------------------------------------------------------------------
nfiles = 1
string_magic("We've found {#n.no ? nfiles} file{#s}.")

nfiles = 0
string_magic("We've found {#n.no ? nfiles} file{#s}.")

nfiles = 0
string_magic("We've found {#n.no ? nfiles} file{#s.0}.")

nfiles = 4
string_magic("We've found {#n.no ? nfiles} file{#s.0}.")

## -----------------------------------------------------------------------------
ndir = 1
string_magic("We've found {ndir} director{#y}.")

ndir = 5
string_magic("We've found {ndir} director{#y}.")

ndir = 1
string_magic("We've found {ndir} director{#ies}.")

## -----------------------------------------------------------------------------
fruits = c("apples", "oranges")
string_magic("The fruit{$s ? fruits} I love {$are, enum}.")

fruits = "apples"
string_magic("The fruit{$s ? fruits} I love {$are, enum}.")

## -----------------------------------------------------------------------------
nfiles = 5
string_magic("{#N.upper.No ? nfiles} file{#s, are} compromised.")

nfiles = 1
string_magic("{#N.upper.No ? nfiles} file{#s, are} compromised.")

nfiles = 0
string_magic("{#N.upper.No ? nfiles} file{#s, are} compromised.")

# Using free-form arguments
nfiles = 5
string_magic("{#'Absolutely no'N.upper ? nfiles} file{#s, are} compromised.")

nfiles = 0
string_magic("{#'Absolutely no'N.upper ? nfiles} file{#s, are} compromised.")

## -----------------------------------------------------------------------------
n = 2
string_magic("Writing the same sentence {#Ntimes ? n} is unnecessary.")

## -----------------------------------------------------------------------------
pple = c("Francis", "Henry")
cat_magic("{$enum, is, (a;) ? pple} tall guy{$s}.",
        "{$(He;They), like} to eat donuts.",
        "When happy, at the pub {$(he;they), goes}!",
        "{$Don't, (he;they)} have wit, {$(he;they)} who {$try}?", .sep = "\n")

pple = "Francis"
cat_magic("{$enum, is, (a;) ? pple} tall guy{$s}.",
        "{$(He;They), like} to eat donuts.",
        "When happy, at the pub {$(he;they), goes}!",
        "{$Don't, (he;they)} have wit, {$(he;they)} who {$try}?", .sep = "\n")


## -----------------------------------------------------------------------------
x = 0
string_magic("{#(Sorry, nothing found.;;{#N.upper} match{#es, were} found.)?x}")

x = 1
string_magic("{#(Sorry, nothing found.;;{#N.upper} match{#es, were} found.)?x}")

x = 3
string_magic("{#(Sorry, nothing found.;;{#N.upper} match{#es, were} found.)?x}")

## -----------------------------------------------------------------------------
string_magic("This message has been written on {.date}.")

## -----------------------------------------------------------------------------
string_magic("This message has been written on {.now('%A %B at %Hh%M')}.")

## -----------------------------------------------------------------------------
rnorm_crossprod = function(n, mean = 0, sd = 1){
  # we set the timer
  timer_magic()
  # we compute some stuff
  x = rnorm(n, mean, sd)
  # we can report the time with .timer
  message_magic("{10 align ! Generation}: {.timer}")
  
  res = x %*% x
  message_magic("{10 align ! Product}: {.timer}",
                "{10 align ! Total}: {.timer_total}", .sep = "\n")
  res
}

rnorm_crossprod(1e5)

## -----------------------------------------------------------------------------
rnorm_crossprod = function(n, mean = 0, sd = 1, debug = FALSE){
  # we set the timer
  timer_magic()
  # we compute some stuff
  x = rnorm(n, mean, sd)
  # we can report the time with .timer
  message_magic("{10 align ! Generation}: {.timer}", .trigger = debug)
  
  res = x %*% x
  message_magic("{10 align ! Product}: {.timer}",
                "{10 align ! Total}: {.timer_total}", 
                .sep = "\n", .trigger = debug)
                
  res
}

# timer not shown
rnorm_crossprod(1e5)

# timers shown thanks to the argument
rnorm_crossprod(1e5, debug = TRUE)

