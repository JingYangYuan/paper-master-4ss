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
library(distributional)
library(patchwork)

theme_set(theme_ggdist())

## ----hidden_options, include=FALSE----------------------------------------------------------------
.old_options = options(width = 100)

## ----df-------------------------------------------------------------------------------------------
set.seed(1234)
n = 5000

df = tibble(
  .draw = 1:n,
  intercept = rnorm(n, 3, 1),
  slope = rnorm(n, 1, 0.25),
  x = list(-4:5),
  y = Map(function(x, y) x + y * -4:5, intercept, slope)
) %>%
  unnest(c(x, y))

## ----spaghetti, fig.width = tiny_width, fig.height = tiny_height----------------------------------
df %>%
  filter(.draw %in% 1:100) %>%
  ggplot(aes(x = x, y = y, group = .draw)) +
  geom_line(alpha = 0.25)

## ----summarized_df--------------------------------------------------------------------------------
df %>%
  group_by(x) %>%
  median_qi(y)

## ----one_ribbon, fig.width = tiny_width, fig.height = tiny_height---------------------------------
df %>%
  group_by(x) %>%
  median_qi(y) %>%
  ggplot(aes(x = x, y = y, ymin = .lower, ymax = .upper)) +
  geom_lineribbon(fill = "gray65")

## ----geom_lineribbon, fig.width = tiny_width, fig.height = tiny_height----------------------------
df %>%
  group_by(x) %>%
  median_qi(y, .width = c(.50, .80, .95)) %>%
  ggplot(aes(x = x, y = y, ymin = .lower, ymax = .upper)) +
  geom_lineribbon() +
  scale_fill_brewer()

## ----stat_lineribbon, fig.width = tiny_width, fig.height = tiny_height----------------------------
df %>%
  ggplot(aes(x = x, y = y)) +
  stat_lineribbon() +
  scale_fill_brewer()

## ----stat_lineribbon_gradient, fig.width = tiny_width, fig.height = tiny_height-------------------
df %>%
  ggplot(aes(x = x, y = y, fill = after_stat(.width))) +
  stat_lineribbon(.width = ppoints(50)) +
  scale_fill_distiller() +
  labs(title = "stat_lineribbon(.width = ppoints(50))")

## ----stat_lineribbon_gradient_rampbar, fig.width = tiny_width, fig.height = tiny_height-----------
df %>%
  ggplot(aes(x = x, y = y, fill_ramp = after_stat(.width))) +
  stat_lineribbon(.width = ppoints(50), fill = "#2171b5") +
  scale_fill_ramp_continuous(range = c(1, 0), guide = guide_rampbar(to = "#2171b5")) +
  labs(
    title = "stat_lineribbon(.width = ppoints(50))",
    subtitle = 'aes(fill_ramp = after_stat(.width)) +\nscale_fill_ramp_continuous(guide = "rampbar")'
  )

## ----stat_lineribbon_density, fig.width = tiny_width, fig.height = tiny_height--------------------
withr::with_options(list(ggdist.experimental.slab_data_in_intervals = TRUE), print(
  df %>%
    ggplot(aes(x = x, y = y, fill_ramp = after_stat(ave(pdf_min + pdf_max, .width)))) +
    stat_lineribbon(.width = ppoints(50), fill = "#2171b5") +
    scale_fill_ramp_continuous(name = "density", guide = guide_rampbar(to = "#2171b5")) +
    labs(
      title = "stat_lineribbon(.width = ppoints(50))",
      subtitle = 'aes(fill_ramp = after_stat(ave(pdf_min + pdf_max, .width)))'
    )
))

## ----stat_lineribbon_density_smooth, fig.width = tiny_width, fig.height = tiny_height-------------
withr::with_options(list(ggdist.experimental.slab_data_in_intervals = TRUE), print(
  df %>%
    ggplot(aes(x = x, y = y, fill_ramp = after_stat(ave(pdf_min + pdf_max, .width)))) +
    stat_lineribbon(.width = pnorm(seq(-2.5, 2.5, length.out = 50)), fill = "#2171b5") +
    scale_fill_ramp_continuous(name = "density", guide = guide_rampbar(to = "#2171b5")) +
    labs(
      title = "stat_lineribbon(.width = pnorm(seq(-2.5, 2.5, length.out = 50)))",
      subtitle = 'aes(fill_ramp = after_stat(ave(pdf_min + pdf_max, .width)))'
    )
))

## ----df_2groups-----------------------------------------------------------------------------------
df_2groups = rbind(
  mutate(df, g = "a"),
  mutate(df, g = "b", y = (y - 2) * 0.5)
)

## ----stat_lineribbon_2groups_brewer, fig.width = tiny_width, fig.height = tiny_height-------------
df_2groups %>%
  ggplot(aes(x = x, y = y, color = g)) +
  stat_lineribbon() +
  scale_fill_brewer()

## ----stat_lineribbon_2groups_alpha, fig.width = tiny_width, fig.height = tiny_height--------------
df_2groups %>%
  ggplot(aes(x = x, y = y, fill = g)) +
  stat_lineribbon(alpha = 1/4) +
  labs(title = "stat_lineribbon(aes(fill = g), alpha = 1/4)")

## ----stat_lineribbon_2groups_ramp, fig.width = tiny_width, fig.height = tiny_height---------------
df_2groups %>%
  ggplot(aes(x = x, y = y, fill = g)) +
  stat_lineribbon(aes(fill_ramp = after_stat(level))) +
  labs(title = "stat_lineribbon(aes(fill = g, fill_ramp = after_stat(level)))")

## ----stat_lineribbon_2groups_group_order, fig.width = tiny_width, fig.height = tiny_height--------
df_2groups %>%
  ggplot(aes(x = x, y = y, fill = g)) +
  stat_lineribbon(aes(
    fill_ramp = after_stat(level),
    order = after_stat(interaction(level, group))
  )) +
  labs(title = "stat_lineribbon(aes(order = after_stat(interaction(level, group))))")

## ----analytical_df--------------------------------------------------------------------------------
analytical_df = tibble(
  x = -4:5,
  y_mean = 3 + x,
  y_sd = sqrt(x^2/10 + 1)
)
analytical_df

## ----stat_lineribbon_dist, fig.width = tiny_width, fig.height = tiny_height-----------------------
analytical_df %>%
  ggplot(aes(x = x, ydist = dist_normal(y_mean, y_sd))) +
  stat_lineribbon() +
  scale_fill_brewer()

## ----curve_draws, fig.width = tiny_width, fig.height = tiny_height--------------------------------
k = 11 # number of curves
n = 501
df = tibble(
  .draw = 1:k,
  mean = seq(-5, 5, length.out = k),
  x = list(seq(-15, 15, length.out = n))
) %>%
  unnest(x) %>%
  mutate(y = dnorm(x, mean, 3)/max(dnorm(x, mean, 3)))

df %>%
  ggplot(aes(x = x, y = y)) +
  geom_line(aes(group = .draw), alpha = 0.2)

## ----pointwise_ribbon, fig.width = tiny_width, fig.height = tiny_height---------------------------
df %>%
  group_by(x) %>%
  median_qi(y, .width = .5) %>%
  ggplot(aes(x = x, y = y)) +
  geom_lineribbon(aes(ymin = .lower, ymax = .upper)) +
  geom_line(aes(group = .draw), alpha = 0.15, data = df) +
  scale_fill_brewer() +
  ggtitle("50% pointwise intervals with point_interval()")

## ----curvewise_ribbon, fig.width = tiny_width, fig.height = tiny_height, eval = requireNamespace("posterior", quietly = TRUE)----
df %>%
  group_by(x) %>%
  curve_interval(y, .width = .5) %>%
  ggplot(aes(x = x, y = y)) +
  geom_lineribbon(aes(ymin = .lower, ymax = .upper)) +
  geom_line(aes(group = .draw), alpha = 0.15, data = df) +
  scale_fill_brewer() +
  ggtitle("50% curvewise intervals with curve_interval()")

## ----pointwise_curvewise, fig.width = tiny_width, fig.height = tiny_width, eval = requireNamespace("posterior", quietly = TRUE)----
k = 1000 # number of curves
large_df = tibble(
  .draw = 1:k,
  mean = seq(-5,5, length.out = k),
  x = list(seq(-15,15,length.out = n))
) %>%
  unnest(x) %>%
  mutate(y = dnorm(x, mean, 3)/max(dnorm(x, mean, 3)))

pointwise_plot = large_df %>%
  group_by(x) %>%
  median_qi(y, .width = c(.5, .8, .95)) %>%
  ggplot(aes(x = x, y = y)) +
  geom_hline(yintercept = 1, color = "gray75", linetype = "dashed") +
  geom_lineribbon(aes(ymin = .lower, ymax = .upper)) +
  scale_fill_brewer() +
  ggtitle("point_interval()")

curvewise_plot = large_df %>%
  group_by(x) %>%
  curve_interval(y, .width = c(.5, .8, .95)) %>%
  ggplot(aes(x = x, y = y)) +
  geom_hline(yintercept = 1, color = "gray75", linetype = "dashed") +
  geom_lineribbon(aes(ymin = .lower, ymax = .upper)) +
  scale_fill_brewer() +
  ggtitle("curve_interval()")

pointwise_plot / curvewise_plot

## ----mtcars_boot----------------------------------------------------------------------------------
set.seed(1234)
n = 4000
mpg = seq(min(mtcars$mpg), max(mtcars$mpg), length.out = 100)

mtcars_boot = tibble(
  .draw = 1:n,
  m = lapply(.draw, function(d) loess(
    hp ~ mpg,
    span = 0.9,
    # this lets us predict outside the range of the data
    control = loess.control(surface = "direct"),
    data = slice_sample(mtcars, prop = 1, replace = TRUE)
  )),
  hp = lapply(m, predict, newdata = tibble(mpg)),
  mpg = list(mpg)
) %>%
  select(-m) %>%
  unnest(c(hp, mpg))

## ----mtcars_spaghetti, fig.width = tiny_width, fig.height = tiny_height---------------------------
mtcars_boot %>%
  filter(.draw < 400) %>%
  ggplot(aes(x = mpg, y = hp)) +
  geom_line(aes(group = .draw), alpha = 1/10) +
  geom_point(data = mtcars) +
  coord_cartesian(ylim = c(0, 400))

## ----mtcars_point_interval, fig.width = tiny_width, fig.height = tiny_height----------------------
mtcars_boot %>%
  ggplot(aes(x = mpg, y = hp)) +
  stat_lineribbon(.width = c(.5, .7, .9)) +
  geom_point(data = mtcars) +
  scale_fill_brewer() +
  coord_cartesian(ylim = c(0, 400))

## ----mtcars_curve_interval, fig.width = tiny_width, fig.height = tiny_height, eval = requireNamespace("posterior", quietly = TRUE)----
mtcars_boot %>%
  group_by(mpg) %>%
  curve_interval(hp, .width = c(.5, .7, .9)) %>%
  ggplot(aes(x = mpg, y = hp)) +
  geom_lineribbon(aes(ymin = .lower, ymax = .upper)) +
  geom_point(data = mtcars) +
  scale_fill_brewer() +
  coord_cartesian(ylim = c(0, 400))

## ----mtcars_curve_interval_bd, fig.width = tiny_width, fig.height = tiny_height, eval = requireNamespace("fda", quietly = TRUE) && requireNamespace("posterior", quietly = TRUE)----
mtcars_boot %>%
  group_by(mpg) %>%
  curve_interval(hp, .width = c(.5, .7, .9), .interval = "bd-mbd") %>%
  ggplot(aes(x = mpg, y = hp)) +
  geom_lineribbon(aes(ymin = .lower, ymax = .upper)) +
  geom_point(data = mtcars) +
  scale_fill_brewer() +
  coord_cartesian(ylim = c(0, 400))

## ----reset_options, include=FALSE---------------------------------------------
options(.old_options)

