## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.height = 5,
  fig.width = 5
)

## ----echo = FALSE-------------------------------------------------------------
rm(list = ls())
embed_png <- function(path, dpi = NULL) {
  meta <- attr(png::readPNG(path, native = TRUE, info = TRUE), "info")
  if (!is.null(dpi)) meta$dpi <- rep(dpi, 2)
  knitr::asis_output(paste0(
    "<img src='", path, "'",
    " width=", round(meta$dim[1] / (meta$dpi[1] / 96)),
    " height=", round(meta$dim[2] / (meta$dpi[2] / 96)),
    " style='display: block; margin: auto;'/>"
  ))
}

## -----------------------------------------------------------------------------
# loads sensemakr package
library(sensemakr)

# simulates data
n <- 100
X <- scale(rnorm(n))
Z <- resid_maker(n, X) 
D <- X + Z + resid_maker(n, cbind(X, Z)) 
Y <- X + Z + resid_maker(n, cbind(X, Z, D))

## -----------------------------------------------------------------------------
model.ydx <- lm(Y ~ D + X) 
summary(model.ydx)

## -----------------------------------------------------------------------------
# fits treatment regression
model.dx <- lm(D ~ X)

# computes observed partial R2 of X
r2yx.d <- partial_r2(model.ydx, covariates = "X")
r2dx   <- partial_r2(model.dx, covariates = "X")

## -----------------------------------------------------------------------------
informal_adjusted_estimate <- adjusted_estimate(model.ydx, 
                                                treatment = "D", 
                                                r2dz.x = r2dx, 
                                                r2yz.dx = r2yx.d)

## ----fig.align='center'-------------------------------------------------------
# draws sensitivity contours
ovb_contour_plot(model.ydx,  
                 treatment = "D", 
                 lim = .6)

# adds informal benchmark 
add_bound_to_contour(r2dz.x = r2dx, 
                     r2yz.dx = r2yx.d, 
                     bound_value = informal_adjusted_estimate,
                     bound_label = "Informal benchmark")

## ----echo=FALSE---------------------------------------------------------------
embed_png(path = "collider.png", dpi = 400)

## ----fig.align='center'-------------------------------------------------------
# compute formal bounds
formal_bound <- ovb_bounds(model = model.ydx, 
                           treatment = "D", 
                           benchmark_covariates = "X", 
                           kd = 1, ky = 1)

## ----fig.align='center'-------------------------------------------------------
# contour plot
ovb_contour_plot(model.ydx,  
                 treatment = "D",
                 lim = .6)

add_bound_to_contour(r2dz.x = r2dx, 
                     r2yz.dx = r2yx.d, 
                     bound_value = informal_adjusted_estimate,
                     bound_label = "Informal benchmark")

add_bound_to_contour(bounds = formal_bound,
                     bound_label = "Proper bound")

