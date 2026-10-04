## ----setup, include=FALSE---------------------------------------------------------------
knitr::opts_chunk$set(echo = TRUE, comment = "#>")

is_pander = requireNamespace("pander", quietly = TRUE)
if(is_pander) library(pander)

library(fixest)
setFixest_notes(FALSE)
setFixest_etable(digits = 3)

# Can we compile LaTeX to PNG? Not available during R CMD check.
can_markdown = !nzchar(Sys.getenv("_R_CHECK_PACKAGE_NAME_", ""))

## ----eval = TRUE, results = "hide"------------------------------------------------------
library(fixest)
data(airquality)

# Setting a dictionary 
setFixest_dict(c(Ozone = "Ozone (ppb)", Solar.R = "Solar Radiation (Langleys)",
                 Wind = "Wind Speed (mph)", Temp = "Temperature"))

## ---------------------------------------------------------------------------------------
# On multiple estimations: see the dedicated vignette
est = feols(Ozone ~ Solar.R + sw0(Wind + Temp) | csw(Month, Day), 
            airquality, cluster = ~Day)

## ---------------------------------------------------------------------------------------
etable(est)

## ---------------------------------------------------------------------------------------
etable(est, style.df = style.df(depvar.title = "", fixef.title = "", 
                                fixef.suffix = " fixed effect", yesNo = "yes"))

## ----eval = !is_pander, include = !is_pander--------------------------------------------
# # NOTE:
# # The evaluation of the code of this section requires the
# #   package 'pander' which is not installed.
# # The code output is not reported.

## ----eval = is_pander-------------------------------------------------------------------
library(pander)

etable(est, postprocess.df = pandoc.table.return, style = "rmarkdown")

## ----eval = is_pander-------------------------------------------------------------------
my_style = style.df(depvar.title = "", fixef.title = "", 
                    fixef.suffix = " fixed effect", yesNo = "yes")
setFixest_etable(style.df = my_style, postprocess.df = pandoc.table.return)

## ----eval = is_pander-------------------------------------------------------------------
etable(est[rhs = 2], style = "rmarkdown", caption = "New default values")

## ---------------------------------------------------------------------------------------
est_slopes = feols(Ozone ~ Solar.R + Wind | Day + Month[Temp], airquality)

## ---------------------------------------------------------------------------------------
etable(est, est_slopes, tex = TRUE)

## ----eval = FALSE-----------------------------------------------------------------------
# etable(est, est_slopes, file = "path/to/mytable.tex")

## ----results = 'hide'-------------------------------------------------------------------
etable(est, est_slopes, style.tex = style.tex("aer"), 
       signif.code = NA, fitstat = ~ r2 + n, tex = TRUE)

## ---------------------------------------------------------------------------------------
set_rules = function(x, heavy, light){
  # x: the character vector returned by etable
  
  tex2add = ""
  if(!missing(heavy)){
    tex2add = paste0("\\setlength\\heavyrulewidth{", heavy, "}\n")
  }
  if(!missing(light)){
    tex2add = paste0(tex2add, "\\setlength\\lightrulewidth{", light, "}\n")
  }
  
  if(nchar(tex2add) > 0){
    x[x == "%start:tab\n"] = tex2add
  }
  
  x
}

## ----include = FALSE--------------------------------------------------------------------
if (can_markdown) setFixest_etable(markdown = TRUE, page.width = "a4")

## ----results = 'asis'-------------------------------------------------------------------
etable(est, est_slopes, postprocess.tex = set_rules, heavy = "0.14em", tex = TRUE)

## ---------------------------------------------------------------------------------------
setFixest_etable(style.tex = style.tex("aer", signif.code = NA), postprocess.tex = set_rules, 
                 fitstat = ~ r2 + n)

## ----results = 'asis'-------------------------------------------------------------------
etable(est, heavy = "0.14em", tex = TRUE)

## ----results = 'asis'-------------------------------------------------------------------
nm = names(iris)
est_iris = feols(.[nm[1]] ~ .[nm[2:4]], iris, fsplit = ~Species)

etable(est_iris, arraystretch = 1.5, tex = TRUE,
       highlight = .("Sepal@1", 
                     "cyan4, square" = "Petal.L@3-4",
                     "thick5, sep8, darkgreen!90, se" = "Petal.W"))

## ----results = 'asis'-------------------------------------------------------------------
etable(est_iris, arraystretch = 1.5, tex = TRUE,
       highlight = .(rowcol = "Sepal@1", 
                     "rowcol, cyan4!70" = "Petal.L@3-4",
                     "rowcol, darkgreen!40, se" = "Petal.W"))

## ----results = 'asis'-------------------------------------------------------------------
etable(est_iris, tex = TRUE,
       coef.style = .(":coef:$\\bigstar$" = "Sepal@1", 
                      "**:coef:**" = "Petal.L@3-4",
                      "\\color{BrickRed} :coef_se:" = "Petal.W"))

## ----results = 'asis'-------------------------------------------------------------------
# First define notes in the dictionary
setFixest_dict(c(note1 = paste0("*Notes*: This is a note that illustrates how to access notes ",
                                "from the dictionary."),
                 source = "*Sources*: Somewhere from the net."))

etable(est, 
       style.tex = style.tex("aer", tpt = TRUE, notes.tpt.intro = "\\footnotesize"),
       notes = c("note1", "source"), tex = TRUE)

## ----results = 'asis'-------------------------------------------------------------------
# Setting up tpt globally
my_style = style.tex(tpt = TRUE, 
                     notes.tpt.intro = "\\footnotesize")
setFixest_etable(style.tex = my_style)

# Below is identical to: 
#  etable(est, 
#         style.tex = style.tex(notes.tpt.intro = "\\Large"),
#         notes = "These notes are large.")
etable(est, notes = c("@\\Large", "These notes are large."), tex = TRUE)

## ----results = 'asis'-------------------------------------------------------------------
est_many = feols(Ozone ~ mvsw(Solar.R, Wind, Temp), airquality)
etable(est_many, adjustbox = 1.1, tex = TRUE)

## ---------------------------------------------------------------------------------------
# Reset defaults from previous sections
setFixest_etable(reset = TRUE)

## ----include = FALSE--------------------------------------------------------------------
if (can_markdown) setFixest_etable(markdown = TRUE, page.width = "a4")

## ----results = 'asis'-------------------------------------------------------------------
etable(est, headers = .("\n\n Short header" = 2, "*Very* \n **long** \n ***header***" = 2),
       tex = TRUE)

## ----include = FALSE--------------------------------------------------------------------
if (can_markdown) setFixest_etable(markdown = FALSE)

## ---------------------------------------------------------------------------------------
# Reset defaults from previous sections
setFixest_etable(reset = TRUE)
setFixest_dict(c(Ozone = "Ozone (ppb)", Solar.R = "Solar Radiation (Langleys)",
                 Wind = "Wind Speed (mph)", Temp = "Temperature"))

fitstat_register(type = "p_s", alias = "pvalue (standard)",
                 fun = function(x) pvalue(x, vcov = "iid")["Solar.R"])

fitstat_register(type = "p_h", alias = "pvalue (Heterosk.)",
                 fun = function(x) pvalue(x, vcov = "hetero")["Solar.R"])

fitstat_register(type = "p_day", alias = "pvalue (Day)",
                 fun = function(x) pvalue(x, vcov = ~Day)["Solar.R"])

fitstat_register(type = "p_month", alias = "pvalue (Month)",
                 fun = function(x) pvalue(x, vcov = ~Month)["Solar.R"])

# Now we display the results with the new fit statistics
etable(est, fitstat = ~ . + p_s + p_h + p_day + p_month)

## ----eval = FALSE-----------------------------------------------------------------------
# summary(.l(est, est_slopes), cluster = ~ Month)

