
<!-- README.md is generated from README.Rmd. Please edit that file -->

# *arg*: Clean and Simple Argument Checking <img src="man/figures/logo.png" align="right" width="150"/>

<!-- badges: start -->

[![CRAN
status](https://www.r-pkg.org/badges/version/arg?color=fe423b)](https://CRAN.R-project.org/package=arg)
[![CRAN_Downloads_Badge](https://cranlogs.r-pkg.org/badges/arg?color=fe423b)](https://cran.r-project.org/package=arg)
<!-- badges: end -->

## Overview

*arg* produces nice, clean error messages for checking function
arguments in R packages. I developed *arg* because I often found myself
repeatedly writing the same error messages in my packages, and I wasn’t
satisfied with the other similar R packages available. *arg* uses
[*cli*](https://cli.r-lib.org/) to produce clean and clear errors
without requiring much programming from the developer. These messages
are designed to be clear to the user, avoiding complicated language.
Many messages adapt to the type of (incorrect) input received.

*arg* contains functions for common arguments checks, such as checking
that an argument is a single number (`arg_number()`), a string
(`arg_string()`), a single `TRUE`/`FALSE` value (`arg_flag()`), or a
data frame or matrix (`arg_data()`). In addition, it is possible to
build more complex argument checks using `arg_and()` and `arg_or()`,
which require that all or at least one check is passed, and
`when_not_null()` and `when_supplied()`, which allow for `NULL` or
omitted arguments, respectively.

``` r
library(arg)

z <- "a string"

# Check that `z` is a string
arg_string(z)

# Check that `z` is a number
arg_number(z)
#> Error:
#> ! `z` must be a number.

# Check that `z` is a string of length 2
arg_and(z,
        arg_string,
        arg_length(2L))
#> Error:
#> ! All of the following conditions must be met:
#> ✔ `z` must be a string
#> ✖ `z` must have length 2

# Check that `z` is NA, a flag, or a count
arg_or(z,
       arg_is_NA,
       arg_flag,
       arg_count)
#> Error:
#> ! `z` must be NA, a logical value (TRUE or FALSE), or a count (a
#>   non-negative whole number).
```

*arg* is meant to be friendly to the developer and the user:
implementing and chaining together checks are simple, and the error
messages produced are clean, pretty, and easy to understand for
non-programmers. Consider the following example, where we check an
argument (`vcov`) for validity. Below we compare the *checkmate*
approach and the *arg* approach. As a user, which would you prefer to
see?

``` r
vcov <- list("bad entry")
vcov_strings <- c("HC0", "HC1", "HC2")

# checkmate approach
library(checkmate)
assert(
  check_null(vcov),
  check_function(vcov),
  check_formula(vcov),
  check_matrix(vcov),
  check_choice(vcov, choices = vcov_strings)
)
#> Error:
#> ! Assertion failed. One of the following must apply:
#>  * check_null(vcov): Must be NULL
#>  * check_function(vcov): Must be a function, not 'list'
#>  * check_formula(vcov): Must be a formula, not list
#>  * check_matrix(vcov): Must be of type 'matrix', not 'list'
#>  * check_choice(vcov): Must be element of set {'HC0','HC1','HC2'}, but
#>  * is not atomic scalar

# arg approach
when_not_null(
  vcov,
  arg_or(
    arg_function,
    arg_formula(one_sided = TRUE),
    arg_cov,
    arg_and(
      arg_string,
      arg_element(vcov_strings)
    )
  )
)
#> Error:
#> ! When `vcov` is not NULL, at least one of the following conditions must
#>   be met:
#> • `vcov` must be a function; a one-sided formula; or a square, symmetric,
#>   numeric matrix
#> • `vcov` must be a string and one of "HC0", "HC1", or "HC2"
```

Of course, there are some costs to this, notably speed, which is
optimized by other argument checking packages like *checkmate*.

*arg* is meant to be used inside other R packages. Its error-throwing
function `err()` (a wrapper for `rlang::abort()`) automatically includes
the relevant (user-facing) function in its error message.

The name “arg” is meant to be short for “argument”, but also perhaps
represents the sound you would make if you were to encounter an error
when running some code. Hopefully *arg* reduces the number of times
users say “arg!”.

If you use any of my R packages, including
[*clarify*](https://iqss.github.io/clarify/),
[*cobalt*](https://ngreifer.github.io/cobalt/),
[*fwb*](https://ngreifer.github.io/fwb/), or
[*WeightIt*](https://ngreifer.github.io/WeightIt/), you may already be
using *arg*!

## Installation

You can install the development version of *arg* from
[GitHub](https://github.com/ngreifer/arg) with:

``` r
# install.packages("pak")
pak::pak("ngreifer/arg")
```

You can install the stable version on CRAN using

``` r
install.packages("arg")
```

## Related packages

*arg* serves a similar function to other existing packages. These
packages may be better for your purposes and optimize other criteria
that you might prefer:

- [*assertions*](https://selkamand.github.io/assertions/)
- [*checkmate*](https://mllg.github.io/checkmate/)
- [*checkarg*](https://cran.r-project.org/package=checkarg)
- [*chk*](https://poissonconsulting.github.io/chk/)
- [*dreamerr*](https://cran.r-project.org/package=dreamerr)
- [*erify*](https://flujoo.github.io/erify/)
- [*favr*](https://lj-jenkins.github.io/favr/)
