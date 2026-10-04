## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  echo = TRUE,
  collapse = TRUE, 
  comment = "#>"
)

library(stringmagic)

## -----------------------------------------------------------------------------
y = "Petal.Length"
x = c("Sepal.Length", "Petal.Width", "Species")
string_magic("{y} ~ {x}", .default = "' + 'collapse", .post = as.formula)

## -----------------------------------------------------------------------------
fml_builder = string_magic_alias(.default = "' + 'collapse", .post = as.formula)

## -----------------------------------------------------------------------------
fml_builder("{y} ~ {x}")

## -----------------------------------------------------------------------------
x = c("Sepal.Length", "Petal.Width")
fml_builder("{y} ~ {'+'collapse ! scale({x})}")

## -----------------------------------------------------------------------------
my_clean = string_clean_alias(split = "; ", pipe = " >> ")

x = "My name is Bond, James Bond"
# old way
string_clean(x, "e, o => a")

# new way
my_clean(x, "e; o >> a")

## -----------------------------------------------------------------------------
num_mat = string_vec_alias(.nmat = TRUE, .last = "'[\n ,]+'split")
num_mat("1, 2, 3
         7, 5, 0
         0, 0, 1")

## -----------------------------------------------------------------------------
# 1) we register the sequence of regular string_magic operations
string_magic_register_ops("'- | 'paste, '40|-'fill", "h1")
# 2) we use it
string_magic("h1 ! That's my header", .nest = TRUE)

## -----------------------------------------------------------------------------
library(stringmagic)
# A) define the function
fun_emph = function(x, ...) paste0("*", x, "*")
 
# B) register it
string_magic_register_fun(fun_emph, "emph")

# C) use it
x = string_vec("right, now")
string_magic("Take heed, {emph, collapse ? x}.")

## -----------------------------------------------------------------------------
fun_emph = function(x, argument, options, ...){
  arg = argument
  if(nchar(arg) == 0) arg = "*"
  
  if("strong" %in% options){
    arg = paste0(rep(arg, 3), collapse = "")
  }
  
  paste0(arg, x, arg)
}

string_magic_register_fun(fun_emph, "emph", "strong")

x = string_vec("right, now")
string_magic("Take heed, {'_'emph.s, c? x}.")

# In string_magic_register_fun, the valid_option argument is used to validate them.
try(string_magic("Take heed, {'_'emph.aaa, c? x}."))

## -----------------------------------------------------------------------------

keep_varnames = function(x, group, group_flag, ...){
  is_ok = grepl("^[[:alpha:].][[:alnum:]._]*$", x)
  
  if(group_flag != 0){
    group = group[is_ok]
    # recreating the index
    group = unclass(as.factor(group))
  } 
  
  res = x[is_ok]
  # we add the group in an attribute (this is the way)
  attr(res, "group") = group
  
  return(res)
}

string_magic_register_fun(keep_varnames, "keepvar")

expr = c("x1 + 52", "73 %% 5 == x", "y[y > .z_5]")
string_magic("All vars: {'[^[:alnum:]_.]+'split, keepvar, unik, enum.bq ? expr}.")

# thanks to the group flag, we can apply group-wise operations
# we apply cat after the function (using .post) to have a nice display of the newlines 
string_magic("Vars in each expr:\n",
             "{'\n'c ! - {1:3}) {'[^[:alnum:]_.]+'split, ",
                                 "keepvar, ~(unik, enum.bq) ? expr}}", .post = cat)

## -----------------------------------------------------------------------------
string_magic_register_ops("'- | 'paste, '70|-'fill", 
                          alias = "header", 
                          namespace = "superpack")

## -----------------------------------------------------------------------------
time = 0.7
cat_magic("{header!Important message to you, user}",
          "The algorithm converged in {time}s.", 
          .sep = "\n", .namespace = "superpack")

## ----error = TRUE-------------------------------------------------------------
try({
time = 0.7
cat_magic("{header!Important message to you, user}",
          "The algorithm converged in {time}s.", 
          .sep = "\n")
})

## -----------------------------------------------------------------------------
cat_magic = stringmagic::cat_magic_alias(.namespace = "superpack")

## ----error = TRUE-------------------------------------------------------------
try({
time = 0.7
cat_magic("{header!Important message to you, user}",
          "The algorithm converged in {time}s.", 
          .sep = "\n")
})

