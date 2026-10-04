## ----chunk_options, include=FALSE---------------------------------------------
in_pkgdown = requireNamespace("pkgdown", quietly = TRUE) && pkgdown::in_pkgdown()

# image dimensions
if (in_pkgdown) {
  tiny_width = 5.5
  tiny_height = 3 + 2/3
  small_width = med_width = 6.75
  small_height = med_height = 4.5
  large_width = 8
  large_height = 5.25
} else {
  tiny_width = 5
  tiny_height = 3 + 1/3
  small_width = 5
  small_height = 3 + 1/3
  med_width = 5
  med_height = 3 + 1/3
  large_width = 5.5
  large_height = 2/3
}
knitr::opts_chunk$set(
  fig.width = small_width,
  fig.height = small_height
)

# graphics device
if (requireNamespace("ragg", quietly = TRUE)) {
  knitr::opts_chunk$set(
    dev = "ragg_png"
  )
} else if (capabilities("cairo") && Sys.info()[['sysname']] != "Darwin") {
  knitr::opts_chunk$set(
    dev = "png",
    dev.args = list(type = "cairo")
  )
}

# png compression for CRAN
if (!in_pkgdown) {
  knitr::knit_hooks$set(pngquant = knitr::hook_pngquant)
  knitr::opts_chunk$set(pngquant = "--speed=1 --quality=50")
}

## ----setup, message = FALSE, warning = FALSE----------------------------------
library(dplyr)
library(tidyr)
library(ggdist)
library(ggplot2)
library(broom)
library(distributional)

theme_set(theme_ggdist())

## ----hidden_options, include=FALSE----------------------------------------------------------------
.old_options = options(width = 100)

## ----data_gen-------------------------------------------------------------------------------------
set.seed(5)
n = 10
n_condition = 5
ABC =
  tibble(
    condition = rep(c("A","B","C","D","E"), n),
    response = rnorm(n * 5, c(0,1,2,1,-1), 0.5)
  )

## ----data_plot, fig.width = med_width, fig.height = med_height/1.5--------------------------------
ABC %>%
  ggplot(aes(x = response, y = condition)) +
  geom_point(alpha = 0.5) +
  ylab("condition")

## ----m_ABC----------------------------------------------------------------------------------------
m_ABC = lm(response ~ condition, data = ABC)

## ----m_ABC_summary--------------------------------------------------------------------------------
summary(m_ABC)

## ----m_ABC_coefs----------------------------------------------------------------------------------
tidy(m_ABC)

## ----halfeye, fig.width = tiny_width, fig.height = tiny_height------------------------------------
m_ABC %>%
  tidy() %>%
  ggplot(aes(y = term)) +
  stat_halfeye(
    aes(xdist = dist_student_t(df = df.residual(m_ABC), mu = estimate, sigma = std.error))
  )

## ----halfeye_with_data, fig.width = tiny_width, fig.height = tiny_height--------------------------
ABC %>%
  expand(condition) %>%
  augment(m_ABC, newdata = ., se_fit = TRUE) %>%
  ggplot(aes(y = condition)) +
  stat_halfeye(
    aes(xdist = dist_student_t(df = df.residual(m_ABC), mu = .fitted, sigma = .se.fit)),
    scale = .5
  ) +
  # we'll add the data back in too (scale = .5 above adjusts the halfeye height so
  # that the data fit in as well)
  geom_point(aes(x = response), data = ABC, pch = "|", size = 2, position = position_nudge(y = -.15))

## ----gradientinterval, fig.width = tiny_width, fig.height = tiny_height---------------------------
ABC %>%
  expand(condition) %>%
  augment(m_ABC, newdata = ., se_fit = TRUE) %>%
  ggplot(aes(y = condition)) +
  stat_gradientinterval(
    aes(xdist = dist_student_t(df = df.residual(m_ABC), mu = .fitted, sigma = .se.fit)),
    scale = .5, fill_type = "gradient"
  )

## ----ccdfinterval, fig.width = tiny_width, fig.height = tiny_height-------------------------------
ABC %>%
  expand(condition) %>%
  augment(m_ABC, newdata = ., se_fit = TRUE) %>%
  ggplot(aes(y = condition)) +
  stat_ccdfinterval(
    aes(xdist = dist_student_t(df = df.residual(m_ABC), mu = .fitted, sigma = .se.fit))
  )

## ----dotplot, fig.width = tiny_width, fig.height = tiny_height------------------------------------
ABC %>%
  expand(condition) %>%
  augment(m_ABC, newdata = ., se_fit = TRUE) %>%
  ggplot(aes(y = condition)) +
  stat_dots(
    aes(xdist = dist_student_t(df = df.residual(m_ABC), mu = .fitted, sigma = .se.fit)),
    quantiles = 100
  )

## ----m_mpg----------------------------------------------------------------------------------------
m_mpg = lm(mpg ~ hp * cyl, data = mtcars)

## ----lineribbon, fig.width = tiny_width, fig.height = tiny_height---------------------------------
mtcars %>%
  group_by(cyl) %>%
  expand(hp = seq(min(hp), max(hp), length.out = 101)) %>%
  augment(m_mpg, newdata = ., se_fit = TRUE) %>%
  ggplot(aes(x = hp, fill = ordered(cyl), color = ordered(cyl))) +
  stat_lineribbon(
    aes(ydist = dist_student_t(df = df.residual(m_mpg), mu = .fitted, sigma = .se.fit)),
    alpha = 1/4
  ) +
  geom_point(aes(y = mpg), data = mtcars) +
  scale_fill_brewer(palette = "Set2") +
  scale_color_brewer(palette = "Dark2") +
  labs(
    color = "cyl",
    fill = "cyl",
    y = "mpg"
  )

## ----lineribbon_lightened, fig.width = tiny_width, fig.height = tiny_height-----------------------
mtcars %>%
  group_by(cyl) %>%
  expand(hp = seq(min(hp), max(hp), length.out = 101)) %>%
  augment(m_mpg, newdata = ., se_fit = TRUE) %>%
  ggplot(aes(x = hp, color = ordered(cyl))) +
  stat_lineribbon(aes(
    ydist = dist_student_t(df = df.residual(m_mpg), mu = .fitted, sigma = .se.fit),
    fill = ordered(cyl),
    fill_ramp = after_stat(level)
  )) +
  geom_point(aes(y = mpg), data = mtcars) +
  scale_fill_brewer(palette = "Set2") +
  scale_color_brewer(palette = "Dark2") +
  labs(
    color = "cyl",
    fill = "cyl",
    y = "mpg"
  )

## ----reset_options, include=FALSE---------------------------------------------
options(.old_options)

