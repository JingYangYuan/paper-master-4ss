## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

library(stringmagic)

## -----------------------------------------------------------------------------
# 'Split' with its default (comma separation)
string_magic("{Split ! romeo, juliet}")

# result with 's' is different
string_magic("{split ! romeo, juliet}")

# with argument: 's' and 'S' are identical
# note the flag 'fixed' (`f/`) to remove regex interpretation
string_magic("{'f/+'split, '-'collapse ! 5 + 2} = 3")

# group wise operations (here `~(sort, collapse)`, see dedicated section)
prince_talk = c("O that this too too solid flesh would melt",
                "Thaw, and resolve itself into a dew!",
                "Or that the Everlasting had not fix'd",
                "His canon 'gainst self-slaughter!")
cat_magic("Order matters:\n{split, ~(sort, collapse), align.center, lower, upper.sentence,
                            Q, '\n'collapse ? prince_talk}")

## -----------------------------------------------------------------------------
# regular way
x = 1:4
string_magic("And {' and 'collapse ? x}!")

# with s2
string_magic("Choose: {', | or 'collapse ? 2:4}?")

# default of Collapse: enumeration (similar to operation enum)
wines = c("Saint-Estephe", "Margaux")
string_magic("I like {Collapse ? wines}.")

# default of collapse: space concatenation
string_magic("{split, '.{5,}'get, collapse ! I don't like short words}")

## -----------------------------------------------------------------------------
x = c("margo: 32, 1m75", "luke doe: 27, 1m71")
string_magic("{'^\\w+'extract ? x} is {'\\d+'extract.first ? x}")

# illustrating multiple extractions
# group-wise operation (~()) is detailed in its own section
x = c("Combien de marins, combien de capitaines.",
      "Qui sont partis joyeux pour des courses lointaines,",
      "Dans ce morne horizon se sont évanouis !")
string_magic("Endings with i: {'i\\w*'extract, ~(', 'collapse), enum.1 ? x}.")


x = c("6 feet under", "mahogany")
# single extraction
string_magic("{'\\w{3}'x ? x}")

# multiple extraction
string_magic("{'\\w{3}'X ? x}")

## -----------------------------------------------------------------------------
# regex without replacement (ie removing)
string_magic("{'e'replace ! Where is the letter e?}")

# regex with replacement
string_magic("{'(?<!\\b)e => a'replace ! Where is the letter e?}")

# with option "single"
string_magic("{'single/(?<!\\b)e => a'replace ! Where is the letter e?}")

# we replace the full string with the flag total (`t/`)
x = c("Where is the letter e?", "Not this way!")
string_magic("{'total/e => here!'r ? x}")

## -----------------------------------------------------------------------------
# we use the fixed pattern to remove the regex meaning
string_magic("{'f/[, ]'clean ! x[a]}")

## -----------------------------------------------------------------------------
x = row.names(mtcars)
#  we only keep models containing "Merc" and ending with a letter ([[:alpha:]]$)
string_magic("Mercedes models: {'Merc & [[:alpha:]]$'get, '^.+ 'r, enum ? x}.")

models = c("Merc 230", "Merc 450SE", "Merc 480")
# we only ekep the ones in the set
string_magic("Mercedes models: {`models`get.in, enum ? x}.")

## -----------------------------------------------------------------------------
x = c("Mark", "Lucas")
# note that we use the flag `i/` to ignore the case
string_magic("Mark? {'i/mark'is, enum ? x}")

## -----------------------------------------------------------------------------
x = c("Mark", "Lucas", "Markus")
# note that we use the flag `i` to ignore the case and `w` to add word boundaries
string_magic("Mark is number {'iw/mark'which ? x}.")

## -----------------------------------------------------------------------------
string_magic("First 3 mpg values: {3 first, enum ? mtcars$mpg}.")

# you could have done the same with regular R in the expression...
string_magic("First 3 mpg values: {enum ? head(mtcars$mpg, 3)}.")

# ...but not in the middle of an operations chain
string_magic("First 3 integer mpg values: {'f/!.'get, 3 first, enum ? mtcars$mpg}.")

## -----------------------------------------------------------------------------
string_magic("Letters in the middle: {13 first, 5 last, enum ? letters}.")

string_magic("First and last letters: {'3|3'first, enum ? letters}.")

string_magic("Last letters: {-21 first, enum ? letters}.")

## -----------------------------------------------------------------------------
# basic use
string_magic("First 3 letters: {'3'K, q, enum ? letters}.")

# advanced use: using the extra argument
string_magic("The letters are: {q, '3|:rest: others'K, enum ? letters}.")

## -----------------------------------------------------------------------------
string_magic("Last 3 mpg values: {3 last, enum ? mtcars$mpg}.")

string_magic("Removing the 3 last elements leads to {-3 last, enum ! x{1:5}}.")

## -----------------------------------------------------------------------------
x = c("sort", "me")
# basic use
string_magic("{sort, collapse ? x}")

## -----------------------------------------------------------------------------
# first modifying the string before sorting
# here the regex first removes the first word, meaning that we sort on the last names
x = c("Jon Snow", "Khal Drogo")
string_magic("{'.+ 'sort, enum?x}")

## -----------------------------------------------------------------------------
x = "Mark is 34, Bianca is 55, Odette is 101, Julie is 21 and Frank is 5"
# sort on the "character string" number
string_magic("{', | and 'split, '\\D'sort, enum ? x}")

# we extract the numbers, then convert to numeric, then sort
string_magic("{', | and 'split, '\\D'sort.num, enum ? x}")

## -----------------------------------------------------------------------------
# note the difference
x = c(20, 100, 10)

# sorting on numeric
string_magic("{sort, ' + 'collapse ? x}")

# sorting on character since 'n' operation transformed the vector to character
string_magic("{n, sort, ' + 'collapse ? x}")

## -----------------------------------------------------------------------------
string_magic("5 = {dsort, ' + 'collapse ? 2:3}")

## -----------------------------------------------------------------------------
string_magic("{rev, ''collapse ? 1:3}")

## -----------------------------------------------------------------------------
string_magic("Iris species: {unik, upper.first, enum ? iris$Species}.")

## -----------------------------------------------------------------------------
dna = string_split("atagggagctacctgcgcgtcgcccaaaagcaggg", "")
cat_magic("Letters in the DNA seq. {''c, Q? dna}: ",
          "  -      default: {table, enum ? dna}",
          "  - value sorted: {table.sort, enum ? dna}",
          "  -       shares: {'{x} [{round(s * 100)}%]' table, enum ? dna}",
          # `fsort` sorts by **increasing** frequency
          "  - freq. sorted: {'{q ? x}' table.fsort, enum ? dna}",
          .sep = "\n")

## -----------------------------------------------------------------------------
# note: operation `S` splits splits wrt to commas (default behavior)
string_magic("{S!x, y}{2 each ? 1:2}")

# illustrating collapsing
string_magic("Large number: 1{5 each.c ! 0}")

## -----------------------------------------------------------------------------
string_magic("What{6 times.c ! ?}")

## -----------------------------------------------------------------------------
x = c("Luke", "Charles")
string_magic("{'i/lu'rm ? x}")

## -----------------------------------------------------------------------------
x = c("I want to enter.", "Age?", "21.")
string_magic("Nightclub conversation: {rm.noalpha, c ! - {x}}")

## -----------------------------------------------------------------------------
x = c(5, 7, 453, 647)
# here we use a condition: see the dedicated section for more information
string_magic("Small numbers only: {if(.>20 ; nuke), enum ? x}.")

## -----------------------------------------------------------------------------
string_magic("{'3'insert.right, ' + 'collapse ? 1:2}")

## -----------------------------------------------------------------------------
fml = y ~ x1 + x2
# the full formula
string_magic("The estimated model is {dp ? fml}.")
# only the beginning of the formula
string_magic("The estimated model is {10 dp.short ? fml}.")

# deparsing a long function, we keep only the first 5 lines:
cat_magic("The function lm:\n{5 dp ? lm}.")

# using vec to keep the deparsed vector, we add line numbers, then 
# collapse it with newlines
cat_magic("The function lm:\n{'\n'c ! {1:5}: {5 dp.vec ? lm}}")

## -----------------------------------------------------------------------------
x = "MesSeD uP CaSe"
string_magic("from a {x} to {lower?x}")

## -----------------------------------------------------------------------------
x = "hi. how are you? fine."
string_magic("{upper.sentence ? x}")

## -----------------------------------------------------------------------------
x = "bryan is in the KITCHEN"

# default: respects upper cases
string_magic("{title ? x}")

# force: force to title case
string_magic("{title.force ? x}")

# ignore: ignores small prepositions
string_magic("{title.force.ignore ? x}")

## -----------------------------------------------------------------------------
x = "   I    should? review 85 4 this text!!"
cat_magic("v0: {x}", 
          "v1: {ws ? x}",
          "v2: {ws.punct ? x}",
          "v3: {ws.punct.digit ? x}",
          "v4: {ws.punct.digit.isolated ? x}", .sep = "\n")

## -----------------------------------------------------------------------------
x = "  too much space \t\n"
string_magic("With trim: {tws, Q ? x}")

## -----------------------------------------------------------------------------
x = c("Mark", "Pam")
string_magic("Hello {q, enum ? x}!")

## -----------------------------------------------------------------------------
x = c(1, 12345) 
cat_magic("left  : {format, q, enum ? x}", 
          "right : {Format, q, enum ? x}",
          "center: {format.center, q, enum ? x}",
          "zero  : {format.0, q, enum ? x}", .sep = "\n")

## -----------------------------------------------------------------------------
string_magic("pi = {%.3f ? pi}")

## -----------------------------------------------------------------------------
x = c("He is tall", "He isn't young")
string_magic("Is he {stop, ws, enum ? x}?")

## -----------------------------------------------------------------------------
author = "Laurent Bergé"
string_magic("This package has been developped by {ascii ? author}.")

## -----------------------------------------------------------------------------
# rounding at 2 digits
cat_magic("pi = {r2 ? pi}\n",
          # same as above with a different syntax
          "pi = {round.2 ? pi}")

x = c(153, 207.256, 0.00254, 15231312.2)
# keeping one significant digit
cat_magic("v1: {s1, align ? x} ",
          # removing the comma for large numbers and preserving ints
          "v2: {s1.int.nocomma ? x}", .collapse = "\n")
          
# combining signif with round
y = c(pi, 0.00125)
cat_magic("raw: {align ? y} ",
          "s1: {s1, align ? y} ", 
          "r2: {r2, align ? y} ",
          "s1.r2: {s1.r2 ? y}", .collapse = "\n")

# prefix and prefix: use and argument
z = c(55, 22.5, 21)
cat_magic("Costs in euros  : {' €'r1, enum ? z}.",
          "\nCosts in dollars: {'USD |'r1, enum ? z}.")

# non numeric values are preserved
xraw = c("55", "five")
string_magic("Valuess {r1, enum ? xraw}.")
# use the `num` command for more control
string_magic("Values: {num.rm, r1, enum ? xraw}.")

## -----------------------------------------------------------------------------
x = c(5, 12, 52123)
string_magic("She owes {n, '$'paste, enum ? x}.")

# option 0: all same width, no ',' for thousands
cat_magic("|---|\n{n.0, '\n'collapse ? x}")

# option "upper"
n = 5
string_magic("{n.upper ? n} is my favourite number.")

# N: like "n.letter"
x = 5
string_magic("He's {N ? x} years old.")

# roman
string_magic("What's nicer? {collapse?11:13}, {n.roman, c?11:13} or {n.Roman, c?11:13}?")

## -----------------------------------------------------------------------------
n = c(3, 7)
string_magic("They finished {nth, enum ? n}!")

## -----------------------------------------------------------------------------
string_magic("They arrived {nth.compact ? 5:20}.")

## -----------------------------------------------------------------------------
n = c(3, 7)
string_magic("They finished {Nth, enum ? n}!")

## -----------------------------------------------------------------------------
string_magic("They lost {enum ! {ntimes ? c(1, 12)} against {S!Real, Barcelona}}.")

## -----------------------------------------------------------------------------
x = 5
string_magic("This paper was rejected {Ntimes ? x}...")

## -----------------------------------------------------------------------------
string_magic("{19 firstchar, 9 lastchar ! This is a very long sentence}")

string_magic("delete 3 = {-3 firstchar ! delete 3}")

## -----------------------------------------------------------------------------
x = "long sentence"
cat_magic("v0: {x}", 
          "v1: {4 shorten ? x}", 
          "v2: {'4|..'shorten ? x}", 
          "v3: {'4|..'shorten.include ? x}", 
          "v4: {4 shorten.dots ? x}", .sep = "\n")

## -----------------------------------------------------------------------------
life = "full of sound and fury, Signifying nothing"
cat_magic("{'[ ,]+'split, upper.first, fill.center, q, '\n'collapse ? life}")

# fixing the length and filling with 0s
string_magic("{'5|0'fill.right, enum ? c(1, 55)}")

## -----------------------------------------------------------------------------
string_magic("y = {'x'paste, ' + 'collapse ? 1:3}")

## -----------------------------------------------------------------------------
string_magic("y = {'x|0'paste, ' + 'collapse ? 1:3}")

## -----------------------------------------------------------------------------
sun = "The sun \\
is shining."
string_magic("How is the sun? {join ? sun}")

## -----------------------------------------------------------------------------
input = "yes \n\n no"
msg = string_magic("Your input, equal to {escape, bq ? input} is incorrect.")
cat(msg, sep = "\n")

## -----------------------------------------------------------------------------
x = c(5, "six")
cat_magic("   origin: {enum, q ? x}", 
          "      num: {num, enum, q ? x}", 
          "   num.rm: {num.rm, enum, q ? x}", 
          " num.soft: {num.soft, enum, q ? x}", 
          "num.clear: {num.clear, enum, q ? x}", .sep = "\n")

## -----------------------------------------------------------------------------
string_magic("{enum ? 1:5}")

## -----------------------------------------------------------------------------
x = c("Marv", "Nancy")
string_magic("The murderer must be {enum.or ? x}.")

x = c("oranges", "milk", "rice")
string_magic("Shopping list: {enum.i.q ? x}.")

# enum is made for display: when vectors are too long, they are truncated
# default is at 7
x = string_magic("x{sample(100, 30)}")
string_magic("The problematic variables are {'x'sort.num, enum ? x}.")

# you can augment or reduce the numbers to display with an option
string_magic("The problematic variables are {'x'sort.num, enum.3 ? x}.")

## -----------------------------------------------------------------------------
cat_magic("The length of 1:5000:", 
          " - len     = {len ? 1:5000}", 
          " - len.num = {len.num ? 1:5000}", .sep = " \n")

## -----------------------------------------------------------------------------
string_magic("Its size is {Len ? 1:8}")

## -----------------------------------------------------------------------------
x = "this is a long sentence"
cat_magic("------ version 0 ------\n{x}", 
          "------ version 1 ------\n{15 swidth ? x}", 
          "------ version 2 ------\n{'15|#>'swidth ? x}",
          "------ version 3 ------\n{'15|#>_'swidth ? x}", .sep = "\n")

## -----------------------------------------------------------------------------
x = Sys.time()
Sys.sleep(0.15) 
string_magic("Time: {difftime ? x}")

