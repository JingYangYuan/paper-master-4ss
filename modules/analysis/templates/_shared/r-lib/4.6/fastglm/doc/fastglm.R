## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  warning = FALSE,
  echo = TRUE,
  eval = TRUE
)

## ----eval = FALSE, echo=TRUE--------------------------------------------------
# pak::pak("fastglm")
# # pak::pak("jaredhuling/fastglm") #development version

## ----echo=TRUE----------------------------------------------------------------
library(fastglm)

## ----echo = TRUE--------------------------------------------------------------
data(esoph)
x <- model.matrix(~ agegp + unclass(tobgp) + unclass(alcgp),
                  data = esoph)

y <- cbind(esoph$ncases, esoph$ncontrols)

gfit1 <- fastglm(x = x, y = y, family = binomial(link = "cloglog"))

summary(gfit1)

## -----------------------------------------------------------------------------
gfit2 <- glm(cbind(ncases, ncontrols) ~ agegp + unclass(tobgp) +
                 unclass(alcgp), data = esoph,
             family = binomial(link = "cloglog"),
             method = fastglm_fit)

summary(gfit2, refit = FALSE)

## ----fig.show='hold'----------------------------------------------------------
set.seed(1)
x <- matrix(rnorm(10000 * 100), ncol = 100)
y <- exp(0.25 * x[,1] - 0.25 * x[,3] + 0.5 * x[,4] - 0.5 * x[,5] + rnorm(10000)) + 0.1


# fastglm
system.time(gfit1 <- glm(y ~ x, family = Gamma(link = "sqrt"),
                         method = fastglm_fit))

# glm
system.time(gfit2 <- glm(y ~ x, family = Gamma(link = "sqrt")))

# glm2
system.time(gfit3 <- glm(y ~ x, family = Gamma(link = "sqrt"),
                         method = glm2::glm.fit2))

## Note that fastglm() returns estimates with the
## largest likelihood
logLik(gfit1)
logLik(gfit2)
logLik(gfit3)

coef(gfit1)[1:5]
coef(gfit2)[1:5]
coef(gfit3)[1:5]

## check convergence of fastglm
gfit1$converged
## number of IRLS iterations
gfit1$iter

## now check convergence for glm()
gfit2$converged
gfit2$iter

## check convergence for glm2()
gfit3$converged
gfit3$iter


## increasing number of IRLS iterations for glm() does not help that much
system.time(gfit2 <- glm(y ~ x, family = Gamma(link = "sqrt"),
                         control = list(maxit = 100)))

gfit2$converged
gfit2$iter

logLik(gfit1)
logLik(gfit2)


