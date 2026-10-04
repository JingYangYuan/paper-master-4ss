## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  fig.height = 4.5,
  fig.width = 4.5,
  fig.align = 'center',
  collapse = TRUE,
  comment = "#>"
)

## ----message=FALSE------------------------------------------------------------
# loads package
library(sensemakr)

# loads data
data("darfur")

## -----------------------------------------------------------------------------
# runs regression model
darfur.model <- lm(peacefactor ~ directlyharmed  + village +  female +
                     age + farmer_dar + herder_dar + pastvoted + hhsize_darfur, 
                   data = darfur)

## ----echo=FALSE,  comment = ""------------------------------------------------
stargazer::stargazer(darfur.model, keep = "directlyharmed", type = "text")

## ----eval=FALSE---------------------------------------------------------------
#  darfur.complete.model <- lm(peacefactor ~ directlyharmed  + village +  female +
#                                age + farmer_dar + herder_dar + pastvoted + hhsize_darfur +
#                                center*wealth*political_attitudes,
#                              data = darfur)

## ----results = 'asis'---------------------------------------------------------
# runs sensemakr for sensitivity analysis
# in the darfur example
darfur.sensitivity <- sensemakr(model = darfur.model, 
                                treatment = "directlyharmed",
                                benchmark_covariates = "female",
                                kd = 1:3,
                                ky = 1:3, 
                                q = 1,
                                alpha = 0.05, 
                                reduce = TRUE)

## -----------------------------------------------------------------------------
darfur.sensitivity <- sensemakr(model = darfur.model, 
                                treatment = "directlyharmed",
                                benchmark_covariates = "female",
                                kd = 1:3)

## -----------------------------------------------------------------------------
darfur.sensitivity

## ----results='asis'-----------------------------------------------------------
ovb_minimal_reporting(darfur.sensitivity, format = "html")

## ----results='hide'-----------------------------------------------------------
summary(darfur.sensitivity)

## -----------------------------------------------------------------------------
plot(darfur.sensitivity)

## -----------------------------------------------------------------------------
plot(darfur.sensitivity, sensitivity.of = "t-value")

## ----fig.width=6--------------------------------------------------------------
plot(darfur.sensitivity, type = "extreme")

