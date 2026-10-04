## ----foo,include=FALSE,echo=FALSE-------------------------
options(keep.source = TRUE, width = 60,
        try.outFile=stdout()  # make try to produce error messages
        )
set.seed(34)

## ---------------------------------------------------------
NH <- 3
NT <- 7

## ---------------------------------------------------------
loglik <- function(p) {
   NH*log(p) + NT*log(1-p)
}

## ---------------------------------------------------------
library(maxLik)
m <- maxLik(loglik, start=0.5)
summary(m)

## ---------------------------------------------------------
x1 <- rnorm(1)  # centered around 0
x2 <- rnorm(1)
x1
x2

## ---------------------------------------------------------
loglik <- function(mu) {
   -2*log(sqrt(2*pi)) - 0.5*((x1 - mu)^2 + (x2 - mu)^2)
}

## ---------------------------------------------------------
m <- maxLik(loglik, start=0)
summary(m)

## ---------------------------------------------------------
(x1 + x2)/2

## ---------------------------------------------------------
data(CO2)
hist(CO2$uptake)

## ---------------------------------------------------------
loglik <- function(theta) {
   mu <- theta[1]
   sigma <- theta[2]
   N <- nrow(CO2)
   -N*log(sqrt(2*pi)) - N*log(sigma) -
      0.5*sum((CO2$uptake - mu)^2/sigma^2)
}

## ---------------------------------------------------------
m <- maxLik(loglik, start=c(mu=30, sigma=10))
summary(m)

## ---------------------------------------------------------
loglik <- function(theta) {
   beta0 <- theta[1]
   beta1 <- theta[2]
   sigma <- theta[3]
   N <- nrow(CO2)
   ## compute new mu based on beta1, beta2
   mu <- beta0 + beta1*CO2$conc
   ## use this mu in a similar fashion as previously
   -N*log(sqrt(2*pi)) - N*log(sigma) -
      0.5*sum((CO2$uptake - mu)^2/sigma^2)
}
m <- maxLik(loglik, start=c(beta0=30, beta1=0, sigma=10))
summary(m)

## ---------------------------------------------------------
summary(lm(uptake ~ conc, data=CO2))

## ----plotSurface, echo=FALSE------------------------------
loglik <- function(theta) {
   mu <- theta[1]
   sigma <- theta[2]
   N <- nrow(CO2)
   -N*log(sqrt(2*pi)) - N*log(sigma) -
      0.5*sum((CO2$uptake - mu)^2/sigma^2)
}
m <- maxLik(loglik, start=c(mu=30, sigma=10))
params <- coef(m)
np <- 33  # number of points
mu <- seq(6, 36, length.out=np)
sigma <- seq(5, 50, length.out=np)
X <- as.matrix(expand.grid(mu=mu, sigma=sigma))
ll <- matrix(apply(X, 1, loglik), nrow=np)
levels <- quantile(ll, c(0.05, 0.4, 0.6, 0.8, 0.9, 0.97))
                           # where to draw the contours
colors <- colorRampPalette(c("Blue", "White"))(30)
par(mar=c(0,0,0,0),
    mgp=2:0)
## Perspective plot
if(require(plot3D)) {
   persp3D(mu, sigma, ll, 
           xlab=expression(mu),
           ylab=expression(sigma),
           zlab=expression(log-likelihood),
           theta=40, phi=30,
           colkey=FALSE,
           col=colors, alpha=0.5, facets=TRUE,
           shade=1,
           lighting="ambient", lphi=60, ltheta=0,
           image=TRUE,
           bty="b2",
           contour=list(col="gray", side=c("z"), levels=levels)
           )
   ## add the dot for maximum
   scatter3D(rep(coef(m)[1], 2), rep(coef(m)[2], 2), c(maxValue(m), min(ll)),
             col="red", pch=16, facets=FALSE,
             bty="n", add=TRUE)
   ## line from max on persp to max at bottom surface
   segments3D(coef(m)[1], coef(m)[2], maxValue(m),
              coef(m)[1], coef(m)[2], min(ll),
              col="red", lty=2,
              bty="n", add=TRUE)
   ## contours for the bottom image
   contour3D(mu, sigma, z=min(ll) + 0.1, colvar=ll, col="black",
             levels=levels,
             add=TRUE)
} else {
   plot(1:2, type="n")
   text(1.5, 1.5, "This figure requires 'plot3D' package",
        cex=1.5)
}

