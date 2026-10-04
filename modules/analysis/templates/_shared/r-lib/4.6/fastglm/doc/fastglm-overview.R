## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  warning = FALSE,
  message = FALSE,
  echo = TRUE,
  eval = TRUE
)

## -----------------------------------------------------------------------------
library(fastglm)

## -----------------------------------------------------------------------------
data(esoph)
x <- model.matrix(~ agegp + unclass(tobgp) + unclass(alcgp),
                  data = esoph)
y <- cbind(esoph$ncases, esoph$ncontrols)

fit <- fastglm(x, y, family = binomial(link = "cloglog"))
summary(fit)

## -----------------------------------------------------------------------------
fit2 <- glm(cbind(ncases, ncontrols) ~ agegp + unclass(tobgp) + unclass(alcgp),
            data = esoph, family = binomial(link = "cloglog"),
            method = fastglm_fit)

## -----------------------------------------------------------------------------
set.seed(123)
n <- 5000; p <- 30
x <- matrix(rnorm(n * p), n, p)
y <- rbinom(n, 1, plogis(x %*% rnorm(p) * 0.05))

system.time(f0 <- fastglm(x, y, family = binomial()))                 # default
system.time(f2 <- fastglm(x, y, family = binomial(), method = 2))     # LLT
system.time(f3 <- fastglm(x, y, family = binomial(), method = 3))     # LDLT

## -----------------------------------------------------------------------------
fit <- fastglm(x, y, family = binomial(), method = 2)

V    <- vcov(fit)
dim(V)

## standard errors agree with the diagonal of vcov()
all.equal(sqrt(diag(V)), unname(coef(summary(fit))[, "Std. Error"]))

## -----------------------------------------------------------------------------
library(sandwich)

V_hc <- vcovHC(fit, type = "HC0")
V_hc[1:3, 1:3]

cluster <- rep(seq_len(20), length.out = n)
V_cl    <- vcovCL(fit, cluster = cluster, type = "HC1")
V_cl[1:3, 1:3]

## -----------------------------------------------------------------------------
xnew <- x[1:5, , drop = FALSE]
predict(fit, newdata = xnew, type = "response", se.fit = TRUE)

## -----------------------------------------------------------------------------
n <- 4000
X <- cbind(1, matrix(rnorm(n * 3), n, 3))
y <- rbinom(n, 1, plogis(X %*% c(0.2, 0.4, -0.2, 0.3)))

chunk_size <- 1000
chunks <- function(k) {
    idx <- ((k - 1) * chunk_size + 1):(k * chunk_size)
    list(X = X[idx, , drop = FALSE], y = y[idx])
}

fit_stream <- fastglm_streaming(chunks, n_chunks = 4, family = binomial())
fit_full   <- fastglm(X, y, family = binomial(), method = 2)

max(abs(coef(fit_stream) - coef(fit_full)))

## ----eval = TRUE--------------------------------------------------------------
library(microbenchmark)

set.seed(7)
n <- 50000; p <- 30
x <- matrix(rnorm(n * p), n, p)
y <- rpois(n, exp(x %*% rnorm(p) * 0.05 + 1))

## force the R-callback path by giving the family object an unrecognized name
disguise <- function(fam) { fam$family <- paste0(fam$family, "*"); fam }

mb <- microbenchmark(
    native   = fastglm(x, y, family = poisson(),            method = 2),
    callback = fastglm(x, y, family = disguise(poisson()),  method = 2),
    times = 5L
)
print(mb)

