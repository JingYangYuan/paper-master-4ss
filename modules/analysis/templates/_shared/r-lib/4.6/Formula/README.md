<!-- README.md is generated from README.Rmd. Please edit that file and run knitr::knit("README.Rmd") -->



<img src="https://zeileis.codeberg.page/Formula/Formula.png" align="right" alt="Formula logo" width="100" />

# Extended Formulas in R


## Overview

Infrastructure for extended formulas in R with multiple parts on the
right-hand side and/or multiple responses on the left-hand side.


## Get started

Extended Formula with two right-hand sides for mtcars data:


``` r
library("Formula")
f <- Formula(log(mpg) ~ disp | factor(vs))
mf <- model.frame(f, data = head(mtcars, 3))
```

Extract response and both regressor matrices from model frame:


``` r
model.response(mf)
##     Mazda RX4 Mazda RX4 Wag    Datsun 710 
##      3.044522      3.044522      3.126761
model.matrix(f, data = mf, rhs = 1)
##               (Intercept) disp
## Mazda RX4               1  160
## Mazda RX4 Wag           1  160
## Datsun 710              1  108
## attr(,"assign")
## [1] 0 1
model.matrix(f, data = mf, rhs = 2)
##               (Intercept) factor(vs)1
## Mazda RX4               1           0
## Mazda RX4 Wag           1           0
## Datsun 710              1           1
## attr(,"assign")
## [1] 0 1
## attr(,"contrasts")
## attr(,"contrasts")$`factor(vs)`
## [1] "contr.treatment"
```


## Reference

Zeileis A, Croissant Y (2010).
  "Extended Model Formulas in R: Multiple Parts and Multiple Responses.
   _Journal of Statistical Software_, **34**(1), 1-13.
   [doi:10.18637/jss.v034.i01](https://doi.org/10.18637/jss.v034.i01)


## Installation

The stable version of `Formula` is available from
[CRAN](https://CRAN.R-project.org/package=Formula):

``` r
install.packages("Formula")
```

The latest development version can be installed from
[R-universe](https://zeileis.R-universe.dev/Formula):

``` r
install.packages("Formula", repos = "https://zeileis.R-universe.dev")
```


## License

The package is available under the
[General Public License version 3](https://www.gnu.org/licenses/gpl-3.0.html)
or [version 2](https://www.gnu.org/licenses/old-licenses/gpl-2.0.html)
