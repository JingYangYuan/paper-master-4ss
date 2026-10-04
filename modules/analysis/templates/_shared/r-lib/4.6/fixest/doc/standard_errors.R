## ----setup, include = FALSE-------------------------------------------------------------
knitr::opts_chunk$set(echo = TRUE, eval = TRUE, comment = "#>")
Sys.setenv(lang = "en")
library(fixest)
setFixest_nthreads(1)

## ---------------------------------------------------------------------------------------
library(fixest)
est = feols(mpg ~ wt + hp, mtcars)

## Simple function that computes a Bayesian bootstrap
vcov_bboot = function(x, n_sim = 100) {
  core_env = update(x, only.coef = TRUE, only.env = TRUE)
  n_obs = x$nobs

  res_all = vector("list", n_sim)
  for (i in 1:n_sim) {
    # est_env updates estimate using new weights
    res_all[[i]] = est_env(env = core_env, weights = rexp(n_obs, rate = 1))
  }

  res = do.call(rbind, res_all)

  # Could return just `var(res)` but the named list will display a nice name in `etable`
  return(list("Bayesian Bootstrap" = var(res)))
}

set.seed(1)
est_bboot_se = summary(est, vcov = vcov_bboot(est))
etable(est, est_bboot_se)

## ---------------------------------------------------------------------------------------
data(trade)
gravity = feols(
  log(Euros) ~ log(dist_km) | Destination + Origin + Product + Year,
  trade
)
# Two-way clustered SEs
summary(gravity, vcov = "twoway")
# Two-way clustered SEs, without small sample correction
summary(gravity, vcov = "twoway", ssc = ssc(K.adj = FALSE, G.adj = FALSE))

## ----eval = TRUE, include = FALSE-------------------------------------------------------
is_plm = requireNamespace("plm", quietly = TRUE)

if (!is_plm) {
  knitr::opts_chunk$set(eval = FALSE)
  cat("Evaluation of the next chunks requires 'plm' which is not installed.")
} else {
  knitr::opts_chunk$set(eval = TRUE)

  library(plm)
  library(sandwich)
}


## ----eval = !is_plm, include = !is_plm--------------------------------------------------
# # NOTE:
# # Evaluation of the next chunks requires the package 'plm' which is not installed.
# # The code output is not reported.

## ---------------------------------------------------------------------------------------
library(sandwich)
library(plm)

data(Grunfeld)

# Estimations
res_lm = lm(inv ~ capital, Grunfeld)
res_feols = feols(inv ~ capital, Grunfeld)

# Same standard-errors
rbind(se(res_lm), se(res_feols))

# Heteroskedasticity-robust covariance
se_lm_hc = sqrt(diag(vcovHC(res_lm, type = "HC1")))
se_feols_hc = se(res_feols, vcov = "hetero")
rbind(se_lm_hc, se_feols_hc)

## ---------------------------------------------------------------------------------------

# Estimations
est_lm = lm(inv ~ capital + as.factor(firm) + as.factor(year), Grunfeld)
est_plm = plm(
  inv ~ capital + as.factor(year),
  Grunfeld,
  index = c("firm", "year"),
  model = "within"
)
# we use panel.id so that panel VCOVs can be applied directly
est_feols = feols(
  inv ~ capital | firm + year,
  Grunfeld,
  panel.id = ~ firm + year
)

#
# "iid" standard-errors
#

#  so we need to ask for iid SEs explicitly.
rbind(se(est_lm)["capital"], se(est_plm)["capital"], se(est_feols))

# p-values:
rbind(
  pvalue(est_lm)["capital"],
  pvalue(est_plm)["capital"],
  pvalue(est_feols, vcov = "iid")
)


## ---------------------------------------------------------------------------------------
# Clustered by firm
se_lm_firm = se(vcovCL(est_lm, cluster = ~firm, type = "HC1"))["capital"]
se_plm_firm = se(vcovHC(est_plm, cluster = "group"))["capital"]
se_stata_firm = 0.06328129 # vce(cluster firm)
se_feols_firm = se(est_feols, vcov = ~firm)

rbind(se_lm_firm, se_plm_firm, se_stata_firm, se_feols_firm)

## ---------------------------------------------------------------------------------------
# How to get the lm version
se_feols_firm_lm = se(est_feols, vcov = ~firm, ssc = ssc(K.fixef = "full"))
rbind(se_lm_firm, se_feols_firm_lm)

# How to get the plm version
se_feols_firm_plm = se(
  est_feols,
  vcov = ~firm,
  ssc = ssc(K.fixef = "none", G.adj = FALSE)
)
rbind(se_plm_firm, se_feols_firm_plm)

## ---------------------------------------------------------------------------------------
#
# Newey-west
#

se_plm_NW = se(vcovNW(est_plm))["capital"]
se_feols_NW = se(est_feols, vcov = "NW")

rbind(se_plm_NW, se_feols_NW)

# we can replicate plm's by changing the type of SSC:
rbind(se_plm_NW, se(est_feols, vcov = NW ~ ssc(K.adj = FALSE, G.adj = FALSE)))

#
# Driscoll-Kraay
#

se_plm_DK = se(vcovSCC(est_plm))["capital"]
se_feols_DK = se(est_feols, vcov = "DK")

rbind(se_plm_DK, se_feols_DK)

# Replicating plm's
rbind(se_plm_DK, se(est_feols, vcov = DK ~ ssc(K.adj = FALSE, G.adj = FALSE)))


## ----eval = TRUE, include = FALSE-------------------------------------------------------
is_lfe = requireNamespace("lfe", quietly = TRUE)
is_lfe_plm = is_lfe && is_plm
if (is_lfe) {
  # avoids ugly startup messages popping + does not require the use of the not very elegant suppressPackageStartupMessages
  library(lfe)
}

## ----eval = !is_lfe_plm, include = !is_lfe_plm, echo = FALSE----------------------------
# if (!is_lfe) {
#   cat(
#     "The evaluation of the next chunks of code requires the package 'lfe' which is not installed"
#   )
# } else {
#   cat(
#     "The evaluation of the next chunks of code requires the package 'plm' (for the data set) which is not installed.",
#     "\nThe code output is not reported."
#   )
# }

## ----eval = is_lfe_plm, warning = FALSE-------------------------------------------------
library(lfe)

# lfe: clustered by firm
est_lfe = felm(inv ~ capital | firm + year | 0 | firm, Grunfeld)
se_lfe_firm = se(est_lfe)

# The two are different, and it cannot be directly replicated by feols
rbind(se_lfe_firm, se_feols_firm)

# You have to provide a custom VCOV to replicate lfe's VCOV
my_vcov = vcov(est_feols, vcov = ~firm, ssc = ssc(K.adj = FALSE))
se(est_feols, vcov = my_vcov * 199 / 198) # Note that there are 200 observations

# Differently from feols, the SEs in lfe are different if year is not a FE:
# => now SEs are identical.
rbind(
  se(felm(inv ~ capital + factor(year) | firm | 0 | firm, Grunfeld))["capital"],
  se(feols(inv ~ capital + factor(year) | firm, Grunfeld), vcov = ~firm)[
    "capital"
  ]
)

# Now with two-way clustered standard-errors
est_lfe_2way = felm(inv ~ capital | firm + year | 0 | firm + year, Grunfeld)
se_lfe_2way = se(est_lfe_2way)
se_feols_2way = se(est_feols, vcov = "twoway")
rbind(se_lfe_2way, se_feols_2way)

# To obtain the same SEs, use G.df = "conventional"
sum_feols_2way_conv = summary(est_feols, vcov = twoway ~ ssc(G.df = "conv"))
rbind(se_lfe_2way, se(sum_feols_2way_conv))

# We also obtain the same p-values
rbind(pvalue(est_lfe_2way), pvalue(sum_feols_2way_conv))

## ---------------------------------------------------------------------------------------
setFixest_ssc(ssc(K.adj = FALSE), "cluster")

## ---------------------------------------------------------------------------------------
setFixest_vcov(
  no_FE = "iid",
  one_FE = "cluster",
  two_FE = "hetero",
  panel = "driscoll_kraay"
)

