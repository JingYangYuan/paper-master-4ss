## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(echo = TRUE, eval = TRUE)

## ----echo = FALSE-------------------------------------------------------------
library(dreamerr)
x = 1:5
y = pt

sum_check = function(...){
  check_arg(..., "numeric vector")
  sum(...)
}

Sys.setenv(LANG = "en")


## ----error = TRUE-------------------------------------------------------------
sum(x, y)

## ----error = TRUE-------------------------------------------------------------
sum_check(x, y)

## ----eval = FALSE-------------------------------------------------------------
#  sum_check = function(...){
#    check_arg(..., "numeric vector")
#    sum(...)
#  }

## -----------------------------------------------------------------------------
plot_cor = function(x, y = NULL, line.opts = list(), ...){
  # x: numeric vector, must be given by the user
  check_arg(x, "numeric vector mbt")
  # y: 
  #  - numeric vector of the same length as x
  # - if y is NULL, then x with some noise is assigned to it 
  check_set_arg(y, "NULL{x + rnorm(length(x))} numeric vector len(data)", .data = x)
  
  # We ensure line.opts is a list
  check_arg(line.opts, "named list")
  
  # The linear regression + options from ...
  reg = lm(y ~ x, ...)
  
  # plotting the correlation
  plot(x, y)
  
  # The fit, all arguments are in line.opts
  # col:
  # - if not provided => "firebrick"
  # - partially matched to firebrick or darkblue
  # - otherwise, a positive integer or a character scalar
  check_set_arg(line.opts$col, "NULL{'firebrick'} match(firebrick, darkblue) | scalar(integer, character) GE{0}") 
  # lwd:
  # - if not provided => 2
  # - otherwise a positive integer scalar
  check_set_arg(line.opts$lwd, "integer scalar GE{0} NULL{2}") # check + default
  
  line.opts$a = reg
  do.call("abline", line.opts)
}

plot_cor(rnorm(100), line.opts = list(col = "dark"))


## -----------------------------------------------------------------------------
lm_check = function(formula, data, subset, weights, na.action, method = "qr", model = TRUE, x = FALSE, y = FALSE, qr = TRUE, singular.ok = TRUE, contrasts = NULL, offset, ...){

  # data:
  # - data.frame or named list (a data.frame is a named list, but it is still added for clarity)
  check_arg(data, "data.frame | named list")
  
  # formula:
  # - must be provided by the user (mbt)
  # - must be two-sided (ts)
  # - variables must be in the data or in the environment [var(data, env)]
  check_arg(formula, "ts formula var(data, env) mbt", .data = data)
  
  # subset:
  # - either a logical or an integer vector
  # - can be a variable of the data set (eval)
  check_arg(subset, "eval vector(logical, strict integer)", .data = data)
  
  # weights:
  # - vector of positive integers
  # - can be NULL
  # - can be a variable of the data set (eval)
  check_arg(weights, "eval vector numeric GE{0} safe null", .data = data)

  # na.action:
  # - can be NULL
  # - must be a function with at least one argument
  check_arg(na.action, "null function arg(1,)")

  # method:
  # - either 'qr' or 'model.frame', partially matched
  check_set_arg(method, "match(qr, model.frame)")

  # You can pool arguments of the same type:
  check_arg(model, x, y, qr, singular.ok, "logical scalar")

  # contrasts:
  # - NULL or list
  check_arg(contrasts, "null list")

  # offset:
  # - can be NULL
  # - numeric matrix or vector
  check_arg(offset, "null numeric vmatrix")

  mc = match.call()
  mc[[1]] = as.name("lm")

  eval(mc, parent.frame())
}

## -----------------------------------------------------------------------------
lm_check_bis = function(formula, data, subset, weights, na.action, method = "qr", model = TRUE, x = FALSE, y = FALSE, qr = TRUE, singular.ok = TRUE, contrasts = NULL, offset, ...){

  # data: now only a data.frame and required
  check_arg(data, "data.frame mbt")
  
  # formula: All variables must be in the data
  check_arg(formula, "ts formula var(data) mbt", .data = data)
  
  # subset: => now we can be more precise
  # - if logical: must be of the same length as the data (otherwise it's a mistake)
  # - if integer, can be of any length (strict integer is used, because we don't want it to be logical)
  check_arg(subset, "eval vector strict logical len(data) | vector strict integer", .data = data)
  
  # weights:vector of positive integers, of the same length as the data
  check_arg(weights, "eval vector numeric GE{0} safe null len(data)", .data = data)

  # Below: same as before
  check_arg(na.action, "null function arg(1,)")
  check_set_arg(method, "match(qr, model.frame)")
  check_arg(model, x, y, qr, singular.ok, "logical scalar")
  check_arg(contrasts, "null list")
  
  # we extract the left hand side (it can be multi response)
  y = eval(formula[[2]], data)

  # offset:
  # - if y is a matrix => offset must be a matrix of the same number of columns
  check_arg(offset, "null numeric vmatrix ncol(data)", .data = y)

  mc = match.call()
  mc[[1]] = as.name("lm")

  eval(mc, parent.frame())
}

