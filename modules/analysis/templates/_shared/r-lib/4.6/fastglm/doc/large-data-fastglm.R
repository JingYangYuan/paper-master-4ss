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
set.seed(1)

## -----------------------------------------------------------------------------
library(Matrix)
n <- 5000

## a 50-level factor that interacts with a continuous covariate.
g    <- factor(sample.int(50, n, replace = TRUE))
xnum <- rnorm(n)
Xd   <- model.matrix(~ g * xnum)        # 5000 x 100, mostly zeros
Xs   <- as(Xd, "CsparseMatrix")

object.size(Xd)
object.size(Xs)

beta_true <- rnorm(ncol(Xd)) / 4
y <- rbinom(n, 1, plogis(Xd %*% beta_true))

## fit using the dense and sparse representations
fit_dense  <- fastglm(Xd, y, family = binomial(), method = 2)
fit_sparse <- fastglm(Xs, y, family = binomial(), method = 2)

max(abs(coef(fit_sparse) - coef(fit_dense)))

## ----error = TRUE-------------------------------------------------------------
try({
fastglm(Xs, y, family = binomial(), method = 0)
})

## -----------------------------------------------------------------------------
library(bigmemory)
n <- 20000
p <- 20
X  <- matrix(rnorm(n * p), n, p)
Xb <- as.big.matrix(X)               # in-memory big.matrix; could equally be filebacked

y  <- rbinom(n, 1, plogis(X %*% rnorm(p) * 0.05))

fit_dense <- fastglm(X,  y, family = binomial(), method = 2)
fit_big   <- fastglm(Xb, y, family = binomial(), method = 2)

max(abs(coef(fit_big) - coef(fit_dense)))

## -----------------------------------------------------------------------------
Sys.setenv(FASTGLM_CHUNK_ROWS = "2000")
fit_big_small <- fastglm(Xb, y, family = binomial(), method = 2)
Sys.unsetenv("FASTGLM_CHUNK_ROWS")

max(abs(coef(fit_big_small) - coef(fit_big)))

## ----error = TRUE-------------------------------------------------------------
try({
fastglm(Xb, y, family = binomial(), method = 0)
})

## -----------------------------------------------------------------------------
n <- 10000
p <- 5
X <- cbind(1, matrix(rnorm(n * (p - 1)), n, p - 1))
y <- rbinom(n, 1, plogis(X %*% c(0.2, 0.5, -0.3, 0.4, -0.2)))

## simulate a "data source" that yields the design matrix in 5 row-blocks
chunk_size <- 2000
chunks <- function(k) {
    idx <- ((k - 1) * chunk_size + 1):(k * chunk_size)
    list(X = X[idx, , drop = FALSE], y = y[idx])
}

fit_stream <- fastglm_streaming(chunks, n_chunks = 5, family = binomial())
fit_full   <- fastglm(X, y, family = binomial(), method = 2)

max(abs(coef(fit_stream) - coef(fit_full)))

## -----------------------------------------------------------------------------
n <- 8000
X <- cbind(1, matrix(rnorm(n * 3), n, 3))
ofs <- runif(n, -0.1, 0.1)
pw  <- runif(n,  0.5, 1.5)
y   <- rpois(n, exp(X %*% c(0.2, 0.4, -0.2, 0.3) + ofs))

chunk_size <- 1000
chunks <- function(k) {
    idx <- ((k - 1) * chunk_size + 1):(k * chunk_size)
    list(X = X[idx, , drop = FALSE], y = y[idx],
         offset = ofs[idx], weights = pw[idx])
}

fit_stream <- fastglm_streaming(chunks, n_chunks = 8, family = poisson())
fit_full   <- fastglm(X, y, family = poisson(), offset = ofs, weights = pw, method = 2)

max(abs(coef(fit_stream) - coef(fit_full)))

## ----eval = FALSE-------------------------------------------------------------
# library(arrow)
# ds      <- open_dataset("path/to/data.parquet")
# batches <- as.list(Scanner$create(ds)$ScanBatches())
# 
# chunks <- function(k) {
#     tbl <- as.data.frame(batches[[k]])
#     list(X = model.matrix(~ x1 + x2 + x3, data = tbl),
#          y = tbl$y)
# }
# 
# fit <- fastglm_streaming(chunks,
#                          n_chunks = length(batches),
#                          family   = binomial())

