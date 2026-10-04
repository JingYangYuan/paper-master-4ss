## ----echo=FALSE-------------------------------------------
library(maxLik)
set.seed(6)

## ----warning = FALSE--------------------------------------
x <- rnorm(100)  # data.  true mu = 0, sigma = 1
loglik <- function(theta) {
   mu <- theta[1]
   sigma <- theta[2]
   sum(dnorm(x, mean=mu, sd=sigma, log=TRUE))
}
m <- maxLik(loglik, start=c(mu=1, sigma=2))
                           # give start value somewhat off
summary(m)

## ---------------------------------------------------------
coef(m)

## ---------------------------------------------------------
stdEr(m)

## ---------------------------------------------------------
## create 3 variables with very different scale
X <- cbind(rnorm(100), rnorm(100, sd=1e3), rnorm(100, sd=1e7))
## note: correct coefficients are 1, 1, 1
y <- X %*% c(1,1,1) + rnorm(100)

## ---------------------------------------------------------
negSSE <- function(beta) {
   e <- y - X %*% beta
   -crossprod(e)
                           # note '-': we are maximizing
}
m <- maxLik(negSSE, start=c(0,0,0))
                           # give start values a bit off
summary(m, eigentol=1e-15)

## ---------------------------------------------------------
grad <- function(beta) {
   2*t(y - X %*% beta) %*% X
}

## ---------------------------------------------------------
m <- maxLik(negSSE, grad=grad, start=c(0,0,0))
summary(m, eigentol=1e-15)

## ---------------------------------------------------------
hess <- function(beta) {
   -2*crossprod(X)
}

## ----hessianExample---------------------------------------
m <- maxLik(negSSE, grad=grad, hess=hess, start=c(0,0,0))
summary(m, eigentol=1e-15)

## ----SSEA-------------------------------------------------
negSSEA <- function(beta) {
   ## negative SSE with attributes
   e <- y - X %*% beta  # we will re-use 'e'
   sse <- -crossprod(e)
                           # note '-': we are maximizing
   attr(sse, "gradient") <- 2*t(e) %*% X
   attr(sse, "Hessian") <- -2*crossprod(X)
   sse
}
m <- maxLik(negSSEA, start=c(0,0,0))
summary(m, eigentol=1e-15)

## ---------------------------------------------------------
compareDerivatives(negSSE, grad, t0=c(0,0,0))
                           # 't0' is the parameter value

## ----BFGS-------------------------------------------------
m <- maxLik(loglik, start=c(mu=1, sigma=2),
            method="BFGS")
summary(m)

## ---------------------------------------------------------
loglik <- function(theta) {
   mu <- theta[1]
   sigma <- theta[2]
   N <- length(x)
   -N*log(sqrt(2*pi)) - N*log(sigma) - sum(0.5*(x - mu)^2/sigma^2)
                           # sum over observations
}
gradlikB <- function(theta) {
   ## BHHH-compatible gradient
   mu <- theta[1]
   sigma <- theta[2]
   N <- length(x)  # number of observations
   gradient <- matrix(0, N, 2)  # gradient is matrix:
                           # N datapoints (rows), 2 components
   gradient[, 1] <- (x - mu)/sigma^2
                           # first column: derivative wrt mu
   gradient[, 2] <- -1/sigma + (x - mu)^2/sigma^3
                           # second column: derivative wrt sigma
   gradient
}

## ---------------------------------------------------------
m <- maxLik(loglik, gradlikB, start=c(mu=1, sigma=2),
            method="BHHH")
summary(m)

## ---------------------------------------------------------
loglikB <- function(theta) {
   mu <- theta[1]
   sigma <- theta[2]
   -log(sqrt(2*pi)) - log(sigma) - 0.5*(x - mu)^2/sigma^2
                           # no summing here
                           # also no 'N*' terms as we work by
                           # individual observations
}
m <- maxLik(loglikB, start=c(mu=1, sigma=2),
            method="BHHH")
summary(m)

## ---------------------------------------------------------
m <- maxLik(loglikB, start=c(mu=1, sigma=2),
            method="BHHH",
            control=list(printLevel=3, iterlim=2))
summary(m)

## ---------------------------------------------------------
m <- maxLik(loglikB, start=c(mu=1, sigma=2),
            method="BHHH",
            control=list(reltol=0, gradtol=0))
summary(m)

## ---------------------------------------------------------
loglik <- function(theta, x) {
   mu <- theta[1]
   sigma <- theta[2]
   sum(dnorm(x, mean=mu, sd=sigma, log=TRUE))
}
m <- maxLik(loglik, start=c(mu=1, sigma=2), x=x)
                           # named argument 'x' will be passed
                           # to loglik
summary(m)

## ---------------------------------------------------------
f <- function(theta) {
   x <- theta[1]
   y <- theta[2]
   exp(-x^2 - y^2)
                           # optimum at (0, 0)
}
m <- maxBFGS(f, start=c(1,1))
                           # give start value a bit off
summary(m)

## ---------------------------------------------------------
## create 3 variables, two independent, third collinear
x1 <- rnorm(100)
x2 <- rnorm(100)
x3 <- x1 + x2 + rnorm(100, sd=1e-6)  # highly correlated w/x1, x2
X <- cbind(x1, x2, x3)
y <- X %*% c(1, 1, 1) + rnorm(100)
m <- maxLik(negSSEA, start=c(x1=0, x2=0, x3=0))
                           # negSSEA: negative sum of squared errors
                           # with gradient, hessian attribute
summary(m)

## ---------------------------------------------------------
condiNumber(X)

## ---------------------------------------------------------
x1 <- rnorm(100)
x2 <- rnorm(100)
x3 <- rnorm(100)
X <- cbind(x1, x2, x3)
y <- X %*% c(1, 1, 1) > 0
                           # y values 1/0 linearly separated
loglik <- function(beta) {
   link <- X %*% beta
   sum(ifelse(y > 0, plogis(link, log=TRUE),
              plogis(-link, log=TRUE)))
}
m <- maxLik(loglik, start=c(x1=0, x2=0, x3=0))
summary(m)

## ---------------------------------------------------------
condiNumber(X)

## ---------------------------------------------------------
condiNumber(hessian(m))

## ---------------------------------------------------------
x <- rnorm(100)
loglik <- function(theta) {
   mu <- theta[1]
   sigma <- theta[2]
   sum(dnorm(x, mean=mu, sd=sigma, log=TRUE))
}
m <- maxLik(loglik, start=c(mu=1, sigma=1),
            fixed="sigma")
                           # fix the component named 'sigma'
summary(m)

## ---------------------------------------------------------
f <- function(theta) {
   x <- theta[1]
   y <- theta[2]
   exp(-x^2 - y^2)
                           # optimum at (0, 0)
}
A <- matrix(c(1, 1), ncol=2)
B <- -1
m <- maxNR(f, start=c(1,1),
           constraints=list(eqA=A, eqB=B))
summary(m)

## ---------------------------------------------------------
A <- matrix(c(1, 1), ncol=2)
B <- -1
m <- maxBFGS(f, start=c(1,1),
             constraints=list(ineqA=A, ineqB=B))
summary(m)

## ---------------------------------------------------------
A <- matrix(c(1, 1, 1, -1), ncol=2)
B <- c(-1, -1)
m <- maxBFGS(f, start=c(2, 0),
             constraints=list(ineqA=A, ineqB=B))
summary(m)

