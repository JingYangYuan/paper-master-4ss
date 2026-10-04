## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  warning = FALSE,
  message = FALSE,
  echo = TRUE,
  eval = TRUE
)

## ----eval = FALSE-------------------------------------------------------------
# fastglm(x, y, family = binomial(), firth = TRUE)

## -----------------------------------------------------------------------------
library(fastglm)

## -----------------------------------------------------------------------------
data(sex2, package = "logistf")
X <- model.matrix(~ age + oc + vic + vicl + vis + dia, data = sex2)
y <- sex2$case

fit_f <- fastglm(X, y, family = binomial(), firth = TRUE)
fit_l <- logistf::logistf(case ~ age + oc + vic + vicl + vis + dia,
                          data = sex2, pl = FALSE, plconf = NULL,
                          control = logistf::logistf.control(
                              lconv = 1e-12, gconv = 1e-12, xconv = 1e-12,
                              maxit = 200L))

cbind(fastglm = unname(coef(fit_f)), logistf = unname(coef(fit_l)))
max(abs(unname(coef(fit_f)) - unname(coef(fit_l))))

## -----------------------------------------------------------------------------
mb <- microbenchmark::microbenchmark(
    fastglm = fastglm(X, y, family = binomial(), firth = TRUE),
    logistf = logistf::logistf(case ~ age + oc + vic + vicl + vis + dia,
                               data = sex2, pl = FALSE, plconf = NULL),
    times = 10L
)
print(mb, unit = "ms")

## -----------------------------------------------------------------------------
library(brglm2)
set.seed(123)
n <- 500
x1 <- rnorm(n);  x2 <- rnorm(n)
X <- cbind(1, x1, x2)
eta_true <- 0.5 + 0.3 * x1 - 0.2 * x2

## -----------------------------------------------------------------------------
y_bin <- rbinom(n, 1, plogis(eta_true))
df <- data.frame(y = y_bin, x1 = x1, x2 = x2)

for (lnk in c("logit", "probit", "cloglog")) {
    fam <- binomial(lnk)
    f <- fastglm(X, y_bin, family = fam, firth = TRUE, tol = 1e-10)
    b <- glm(y ~ x1 + x2, data = df, family = fam, method = "brglmFit",
             type = "AS_mean", control = list(epsilon = 1e-10, maxit = 200))
    cat(sprintf("binomial %-8s max|diff| = %.2e\n", lnk,
                max(abs(unname(coef(f)) - unname(coef(b))))))
}

## -----------------------------------------------------------------------------
y_pois <- rpois(n, exp(eta_true))

for (lnk in c("log", "sqrt")) {
    fam <- poisson(lnk)
    f <- fastglm(X, y_pois, family = fam, firth = TRUE, tol = 1e-10)
    b <- glm(y ~ x1 + x2, data = data.frame(y = y_pois, x1 = x1, x2 = x2),
             family = fam, method = "brglmFit", type = "AS_mean",
             control = list(epsilon = 1e-10, maxit = 200))
    cat(sprintf("poisson  %-8s max|diff| = %.2e\n", lnk,
                max(abs(unname(coef(f)) - unname(coef(b))))))
}

## -----------------------------------------------------------------------------
y_gam <- rgamma(n, shape = 5, rate = 5 / exp(eta_true))

for (lnk in c("log", "inverse")) {
    fam <- Gamma(lnk)
    f <- fastglm(X, y_gam, family = fam, firth = TRUE, tol = 1e-10)
    b <- glm(y ~ x1 + x2, data = data.frame(y = y_gam, x1 = x1, x2 = x2),
             family = fam, method = "brglmFit", type = "AS_mean",
             control = list(epsilon = 1e-10, maxit = 200))
    cat(sprintf("Gamma    %-8s max|diff| = %.2e\n", lnk,
                max(abs(unname(coef(f)) - unname(coef(b))))))
}

## -----------------------------------------------------------------------------
y_gauss <- eta_true + rnorm(n, 0, 0.5)

for (lnk in c("identity", "log")) {
    fam <- gaussian(lnk)
    y0 <- if (lnk == "log") pmax(y_gauss, 0.01) else y_gauss
    f <- fastglm(X, y0, family = fam, firth = TRUE, tol = 1e-10)
    b <- glm(y ~ x1 + x2, data = data.frame(y = y0, x1 = x1, x2 = x2),
             family = fam, method = "brglmFit", type = "AS_mean",
             control = list(epsilon = 1e-10, maxit = 200))
    cat(sprintf("gaussian %-8s max|diff| = %.2e\n", lnk,
                max(abs(unname(coef(f)) - unname(coef(b))))))
}

## -----------------------------------------------------------------------------
mu_ig <- exp(eta_true)
y_ig <- statmod::rinvgauss(n, mean = mu_ig, shape = 5)
y_ig[y_ig <= 0] <- 0.01

f <- fastglm(X, y_ig, family = inverse.gaussian("log"), firth = TRUE, tol = 1e-10)
b <- glm(y ~ x1 + x2, data = data.frame(y = y_ig, x1 = x1, x2 = x2),
         family = inverse.gaussian("log"), method = "brglmFit", type = "AS_mean",
         control = list(epsilon = 1e-10, maxit = 200))
cat(sprintf("inv.gauss log      max|diff| = %.2e\n",
            max(abs(unname(coef(f)) - unname(coef(b))))))

## -----------------------------------------------------------------------------
f <- fastglm(X, y_bin, family = binomial(), firth = TRUE, tol = 1e-10)
b <- glm(y ~ x1 + x2, data = df, family = binomial(), method = "brglmFit",
         type = "AS_mean", control = list(epsilon = 1e-10, maxit = 200))

cbind(fastglm_SE = f$se, brglm2_SE = summary(b)$coefficients[, "Std. Error"])
max(abs(f$se - summary(b)$coefficients[, "Std. Error"]))

## -----------------------------------------------------------------------------
f <- fastglm(X, y_bin, family = binomial(), firth = TRUE)
c(deviance = f$deviance,
  log.det.XtWX = f$log.det.XtWX,
  penalized.deviance = f$penalized.deviance)

## -----------------------------------------------------------------------------
set.seed(123)
n <- 10000;  p <- 5
x1 <- rnorm(n);  x2 <- rnorm(n); x3 <- rnorm(n)
x4 <- rnorm(n);  x5 <- rnorm(n)
X <- cbind(1, x1, x2, x3, x4, x5)
eta <- 0.5 + 0.3 * x1 - 0.2 * x2 + 0.1 * x3

families <- list(
    `binomial logit`   = list(fam = binomial("logit"),
                              y = rbinom(n, 1, plogis(eta))),
    `binomial probit`  = list(fam = binomial("probit"),
                              y = rbinom(n, 1, plogis(eta))),
    `binomial cloglog` = list(fam = binomial("cloglog"),
                              y = rbinom(n, 1, plogis(eta))),
    `poisson log`      = list(fam = poisson("log"),
                              y = rpois(n, exp(eta))),
    `Gamma log`        = list(fam = Gamma("log"),
                              y = rgamma(n, shape = 5, rate = 5 / exp(eta))),
    `gaussian identity`= list(fam = gaussian("identity"),
                              y = eta + rnorm(n, 0, 0.5))
)

df <- data.frame(y = 0, x1 = x1, x2 = x2, x3 = x3, x4 = x4, x5 = x5)
results <- list()
for (nm in names(families)) {
    fi <- families[[nm]]
    df$y <- fi$y
    mb <- microbenchmark::microbenchmark(
        fastglm = fastglm(X, fi$y, family = fi$fam, firth = TRUE),
        brglm2  = glm(y ~ x1 + x2 + x3 + x4 + x5, data = df,
                      family = fi$fam, method = "brglmFit", type = "AS_mean"),
        times = 10L
    )
    s <- summary(mb, unit = "ms")
    cat(sprintf("%-20s fastglm=%7.2f ms  brglm2=%7.2f ms  speedup=%.1fx\n",
                nm, s$median[1], s$median[2], s$median[2] / s$median[1]))
}

