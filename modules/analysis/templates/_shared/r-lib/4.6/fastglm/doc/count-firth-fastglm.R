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
suppressPackageStartupMessages({
    library(MASS)        # glm.nb, rnegbin
    library(pscl)        # hurdle, zeroinfl, bioChemists
    library(microbenchmark)
})

## -----------------------------------------------------------------------------
data(quine)
X <- model.matrix(~ Eth + Sex + Age + Lrn, data = quine)
y <- quine$Days

fit_f <- fastglm_nb(X, y)
fit_m <- MASS::glm.nb(Days ~ Eth + Sex + Age + Lrn, data = quine)

c(theta_fastglm = fit_f$theta, theta_glm.nb = fit_m$theta)

max(abs(unname(coef(fit_f)) - unname(coef(fit_m))))
abs(as.numeric(logLik(fit_f)) - as.numeric(logLik(fit_m)))

## -----------------------------------------------------------------------------
set.seed(1)
n  <- 5e4
X  <- cbind(1, matrix(rnorm(n * 3), n, 3))
mu <- exp(X %*% c(0.5, 0.4, -0.2, 0.3))
y  <- MASS::rnegbin(n, mu = mu, theta = 2)
df <- data.frame(y = y, x1 = X[, 2], x2 = X[, 3], x3 = X[, 4])

mb_nb <- microbenchmark(
    fastglm_nb = fastglm_nb(X, y),
    glm.nb     = MASS::glm.nb(y ~ x1 + x2 + x3, data = df),
    times = 5L
)
print(mb_nb)

## -----------------------------------------------------------------------------
fit_joint <- fastglm_nb(X, y)
fit_known <- fastglm(X, y, family = negbin(theta = fit_joint$theta, link = "log"))
max(abs(unname(coef(fit_known)) - unname(coef(fit_joint))))

## -----------------------------------------------------------------------------
data(bioChemists, package = "pscl")
fit_f <- fastglm_hurdle(art ~ ., data = bioChemists, dist = "poisson")
fit_p <- pscl::hurdle (art ~ ., data = bioChemists, dist = "poisson")

max(abs(unname(coef(fit_f, "count")) - unname(fit_p$coefficients$count)))
max(abs(unname(coef(fit_f, "zero"))  - unname(fit_p$coefficients$zero)))
abs(as.numeric(logLik(fit_f)) - as.numeric(logLik(fit_p)))

## -----------------------------------------------------------------------------
coef(fit_f, model = "count")
coef(fit_f, model = "zero")

## -----------------------------------------------------------------------------
set.seed(11)
n  <- 4000
x1 <- rnorm(n);  x2 <- rnorm(n)
lam    <- exp(0.7 + 0.4 * x1 - 0.3 * x2)
is_pos <- rbinom(n, 1, plogis(-0.4 + 0.5 * x1 + 0.2 * x2))
yt     <- integer(n)
for (i in seq_len(n)) {
    repeat { v <- rpois(1, lam[i]); if (v > 0) { yt[i] <- v; break } }
}
y  <- ifelse(is_pos == 1, yt, 0L)
df <- data.frame(y = y, x1 = x1, x2 = x2)

mb_hurdle <- microbenchmark(
    fastglm_hurdle = fastglm_hurdle(y ~ x1 + x2, data = df, dist = "poisson"),
    pscl_hurdle    = pscl::hurdle (y ~ x1 + x2, data = df, dist = "poisson"),
    times = 5L
)
print(mb_hurdle)

## -----------------------------------------------------------------------------
fit_f <- fastglm_zi(art ~ ., data = bioChemists, dist = "poisson",
                    em.tol = 1e-10, em.maxit = 300L)
fit_p <- pscl::zeroinfl(art ~ ., data = bioChemists, dist = "poisson")

max(abs(unname(coef(fit_f, "count")) - unname(fit_p$coefficients$count)))
max(abs(unname(coef(fit_f, "zero"))  - unname(fit_p$coefficients$zero)))
abs(as.numeric(logLik(fit_f)) - as.numeric(logLik(fit_p)))

## -----------------------------------------------------------------------------
set.seed(21)
n  <- 3000
x1 <- rnorm(n);  x2 <- rnorm(n)
eta_c <- 0.7 + 0.4 * x1 - 0.3 * x2
eta_z <- -0.4 + 0.5 * x1 + 0.2 * x2
z     <- rbinom(n, 1, plogis(eta_z))
y     <- ifelse(z == 1, 0L, rpois(n, exp(eta_c)))
df    <- data.frame(y = y, x1 = x1, x2 = x2)

mb_zi <- microbenchmark(
    fastglm_zi = fastglm_zi(y ~ x1 + x2, data = df, dist = "poisson"),
    pscl_zi    = pscl::zeroinfl(y ~ x1 + x2, data = df, dist = "poisson"),
    times = 5L
)
print(mb_zi)

