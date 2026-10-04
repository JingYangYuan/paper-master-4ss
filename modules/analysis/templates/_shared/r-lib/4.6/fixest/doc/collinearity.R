## ----setup, include=FALSE---------------------------------------------------------------
knitr::opts_chunk$set(echo = TRUE, results = "asis", eval = FALSE)
options(width = 90)

## ---------------------------------------------------------------------------------------
# # Illustration of the FWL theorem's magic
# 
# # We use the `iris` data set
# base = setNames(iris, c("y", "x", "z1", "z2", "species"))
# 
# library(fixest)
# # The main estimation, we're only interested in `x`'s coefficient
# est = feols(y ~ x + z1 + z2, base)
# 
# # We estimate both `y` and `x` on the other explanatory variables
# #  and get the matrix of residuals
# resids = feols(c(y, x) ~ z1 + z2, base) |> resid()
# # We estimate y's residuals on x's residuals
# est_fwl = feols.fit(resids[, 1], resids[, 2])
# 
# # We compare the estimates: they are identical
# # The standards errors are also the same, modulo a constant factor
# etable(est, est_fwl, order = "x|resid")
# #>                                 est            est_fwl
# #> Dependent Var.:                   y         resids[,1]
# #>
# #> x                0.6508*** (0.0667)
# #> resids[,2]                          0.6508*** (0.0660)
# #> Constant          1.856*** (0.2508)
# #> z1               0.7091*** (0.0567)
# #> z2              -0.5565*** (0.1275)
# #> _______________ ___________________ __________________
# #> S.E. type                       IID                IID
# #> Observations                    150                150
# #> R2                          0.85861            0.39104
# #> Adj. R2                     0.85571            0.39104
# #> ---
# #> Signif. codes: 0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1

## ---------------------------------------------------------------------------------------
# # We generate the data
# n = 1e6
# n_half = n / 2
# df = data.frame(x = rep(0, n))
# df$x[1:n_half] = 1
# df$y = df$x + rnorm(n)
# 
# # we estimate y on x for various translations of x
# all_trans = c(0, 10 ** (1:5))
# all_results = list()
# for(i in seq_along(all_trans)){
#   trans = all_trans[i]
#   all_results[[i]] = feols(y ~ I(x + trans), df)
# }
# 
# # we display the results
# etable(all_results)
# #>                            model 1            model 2            model 3
# #> Dependent Var.:                  y                  y                  y
# #>
# #> Constant           0.0013 (0.0014) -9.974*** (0.0210) -99.75*** (0.2009)
# #> I(x+0)          0.9975*** (0.0020)
# #> I(x+10)                            0.9975*** (0.0020)
# #> I(x+100)                                              0.9975*** (0.0020)
# #> I(x+1000)
# #> I(x+10000)
# #> I(x+1e+05)
# #> _______________ __________________ __________________ __________________
# #> S.E. type                      IID                IID                IID
# #> Observations             1,000,000          1,000,000          1,000,000
# #> R2                         0.19936            0.19936            0.19936
# #> Adj. R2                    0.19936            0.19936            0.19936
# #>
# #>                            model 4             model 5              model 6
# #> Dependent Var.:                  y                   y                    y
# #>
# #> Constant         -997.5*** (2.000) -9,974.9*** (19.99) -99,749.2*** (199.9)
# #> I(x+0)
# #> I(x+10)
# #> I(x+100)
# #> I(x+1000)       0.9975*** (0.0020)
# #> I(x+10000)                          0.9975*** (0.0020)
# #> I(x+1e+05)                                               0.9975*** (0.0020)
# #> _______________ __________________ ___________________ ____________________
# #> S.E. type                      IID                 IID                  IID
# #> Observations             1,000,000           1,000,000            1,000,000
# #> R2                         0.19936             0.19936              0.19936
# #> Adj. R2                    0.19936             0.19936              0.19936
# #> ---
# #> Signif. codes: 0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1

## ---------------------------------------------------------------------------------------
# # we add 1,000,000 to x
# feols(y ~ I(x + 1e6), df)
# #> The variable 'I(x + 1e+06)' has been removed because of collinearity (see $collin.var).
# #> OLS estimation, Dep. Var.: y
# #> Observations: 1,000,000
# #> Standard-errors: IID
# #>             Estimate Std. Error t value  Pr(>|t|)
# #> (Intercept) 0.500031   0.001117 447.653 < 2.2e-16 ***
# #> ... 1 variable was removed because of collinearity (I(x + 1e+06))
# #> ---
# #> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
# #> RMSE: 1.11701

## ---------------------------------------------------------------------------------------
# lm(y ~ I(x + 1e6), df) |> coef()
# #>   (Intercept)  I(x + 1e+06)
# #> -9.974923e+05  9.974923e-01
# lm(y ~ I(x + 1e7), df) |> coef()
# #> (Intercept) I(x + 1e+07)
# #>    0.500031           NA

## ---------------------------------------------------------------------------------------
# data(base_pub, package = "fixest")
# 
# ## The model:
# feols(nb_pub ~ age + i(author_id) + i(affil_id), base_pub)
# #> The variables 'affil_id::6902469', 'affil_id::9217761', 'affil_id::27504731',
# #> 'affil_id::39965400', 'affil_id::43522216', 'affil_id::47301684' and 45 others have been
# #> removed because of collinearity (see $collin.var).
# #> OLS estimation, Dep. Var.: nb_pub
# #> Observations: 4,024
# #> Standard-errors: IID
# #>                       Estimate Std. Error   t value   Pr(>|t|)
# #> (Intercept)          -4.700489   2.396759 -1.961185 4.9934e-02 *
# #> age                   0.047252   0.006213  7.605218 3.6032e-14 ***
# #> author_id::90561406  -1.458487   0.902767 -1.615574 1.0627e-01
# #> author_id::94862465  -3.390346   1.862776 -1.820050 6.8834e-02 .
# #> author_id::168896994  0.473991   2.447235  0.193684 8.4643e-01
# #> author_id::217986139 -0.133319   1.734549 -0.076861 9.3874e-01
# #> author_id::226108609  0.179560   2.021085  0.088843 9.2921e-01
# #> author_id::231631639  2.799524   3.110143  0.900127 3.6811e-01
# #> ... 397 coefficients remaining (display them with summary() or use argument n)
# #> ... 51 variables were removed because of collinearity (affil_id::6902469,
# #> affil_id::9217761 and 49 others [full set in $collin.var])
# #> ---
# #> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
# #> RMSE: 2.21108   Adj. R2: 0.685792

## ---------------------------------------------------------------------------------------
# feols(nb_pub ~ age | author_id + affil_id, base_pub, vcov = "iid")
# #> OLS estimation, Dep. Var.: nb_pub
# #> Observations: 4,024
# #> Fixed-effects: author_id: 200,  affil_id: 256
# #> Standard-errors: IID
# #>     Estimate Std. Error t value   Pr(>|t|)
# #> age 0.047252   0.006257 7.55144 5.4359e-14 ***
# #> ---
# #> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
# #> RMSE: 2.21108     Adj. R2: 0.681301
# #>                 Within R2: 0.015731

## ---------------------------------------------------------------------------------------
# feols(nb_pub ~ is_woman + age + i(author_id) + i(year), base_pub)
# #> The variables 'author_id::2747123765' and 'year::2000' have been removed because of
# #> collinearity (see $collin.var).
# #> OLS estimation, Dep. Var.: nb_pub
# #> Observations: 4,024
# #> Standard-errors: IID
# #>                       Estimate Std. Error   t value Pr(>|t|)
# #> (Intercept)           3.224328   2.203459  1.463303  0.14347
# #> is_woman             -0.673406   1.624295 -0.414583  0.67847
# #> age                   0.046843   0.045423  1.031271  0.30248
# #> author_id::90561406  -1.028373   1.093804 -0.940180  0.34719
# #> author_id::94862465  -1.953734   0.985021 -1.983444  0.04739 *
# #> author_id::168896994 -1.449938   0.914733 -1.585094  0.11303
# #> author_id::217986139 -1.576761   0.923925 -1.706591  0.08798 .
# #> author_id::226108609 -0.568410   1.171480 -0.485207  0.62756
# #> ... 242 coefficients remaining (display them with summary() or use argument n)
# #> ... 2 variables were removed because of collinearity (author_id::2747123765 and
# #> year::2000)
# #> ---
# #> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
# #> RMSE: 2.96683   Adj. R2: 0.457524

## ---------------------------------------------------------------------------------------
# # same estimation as above
# est_num = feols(nb_pub ~ is_woman + age + i(author_id) + i(year), base_pub)
# #> The variables 'author_id::2747123765' and 'year::2000' have been removed because of
# #> collinearity (see $collin.var).
# 
# # we create `author_id_char`: same as `author_id` but in character form
# base_pub$author_id_char = as.character(base_pub$author_id)
# 
# # replacing `author_id` with `author_id_char`: both variables contain the same information
# est_char = feols(nb_pub ~ is_woman + age + i(author_id_char) + i(year), base_pub)
# #> The variables 'author_id_char::731914895' and 'year::2000' have been removed because of
# #> collinearity (see $collin.var).
# 
# etable(est_num, est_char, keep = "woman|age")
# #>                         est_num        est_char
# #> Dependent Var.:          nb_pub          nb_pub
# #>
# #> is_woman        -0.6734 (1.624)   1.729 (3.174)
# #> age             0.0468 (0.0454) 0.0468 (0.0454)
# #> _______________ _______________ _______________
# #> S.E. type                   IID             IID
# #> Observations              4,024           4,024
# #> R2                      0.49110         0.49110
# #> Adj. R2                 0.45752         0.45752
# #> ---
# #> Signif. codes: 0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1

## ---------------------------------------------------------------------------------------
# est_last = feols(nb_pub ~ i(author_id) + i(year) + is_woman + age, base_pub)
# #> The variables 'is_woman' and 'age' have been removed because of collinearity (see
# #> $collin.var).

## ---------------------------------------------------------------------------------------
# feols(nb_pub ~ is_woman + age | author_id + year, base_pub)
# #> Error: in feols(nb_pub ~ is_woman + age | author_id + year,...:
# #> All variables, 'is_woman' and 'age', are collinear with the fixed effects. Without
# #> doubt, your model is misspecified.

