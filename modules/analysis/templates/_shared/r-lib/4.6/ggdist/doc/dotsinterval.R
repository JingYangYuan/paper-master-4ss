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
library(distributional)
library(ggdist)
library(ggplot2)
library(patchwork)

theme_set(theme_ggdist())

## ----hidden_options, include=FALSE----------------------------------------------------------------
.old_options = options(width = 100)

## ----dotsinterval_components, echo=FALSE, fig.height=4.15, fig.width=6.5--------------------------
red_ = "#d95f02"
green_ = "#1b9e77"
blue_ = "#7570b3"

bracket_ = function(..., x, xend = x, y, yend = y, color = red_) {
  annotate("segment",
    arrow = arrow(angle = 90, ends = "both", length = unit(3, "points")),
    color = color, linewidth = 0.75,
    x = x, xend = xend, y = y, yend = yend,
    ...
  )
}
thickness_ = function(x) dnorm(x,4,1) * 0.9 / dnorm(4,4,1)
refline_ = function(..., x, xend = x, y, yend = y, color = red_, linetype = "solid", alpha = 0.5) {
  annotate("segment",
    color = color, linetype = linetype, alpha = alpha, linewidth = 0.75,
    x = x, xend = xend, y = y, yend = yend,
    ...
  )
}
label_ = function(..., hjust = 0, color = red_) {
  annotate("text",
    color = color, hjust = hjust, lineheight = 1,
    size = 3.25,
    ...
  )
}
arrow_ = function(..., curvature = 0, x, xend = x, y, yend = y) {
  annotate("curve",
    color = red_, arrow = arrow(angle = 45, length = unit(3, "points"), type = "closed"),
    curvature = curvature,
    x = x, xend = xend, y = y, yend = yend
  )
}


tibble(dist = dist_normal(4, 1.2)) %>%
  ggplot(aes(y = 0, xdist = dist)) +

  geom_hline(yintercept = 0:1, color = "gray95") +

  stat_dotsinterval(
    aes(linewidth = NULL),
    slab_color = "gray50",
    .width = 1 - 2*pnorm(-1, sd = 1.2),
    fill = "gray75",
    point_size = 5,
    shape = 22,
    slab_shape = 21,
    stroke = 1.5,
    linewidth = 5,
    slab_linewidth = 1.5
  ) +

  # height
  refline_(x = 0, xend = 8.4, y = 1) +
  bracket_(x = 8.4, y = 0, yend = 1) +
  label_(label = "height", x = 8.6, y = 1) +

  # scale
  refline_(x = 4, xend = 8.6, y = 0.9) +
  bracket_(x = 8.6, y = 0, yend = 0.9) +
  label_(label = "scale = 0.9", x = 8.8, y = 0.9) +

  # slab line properties
  label_(x = 2.5, y = 0.7,
    label = 'slab_color = "gray50"\nslab_linewidth = 1.5',
    vjust = 1, hjust = 1
  ) +
  arrow_(x = 2.52, xend = 3, y = 0.67, yend = thickness_(3.1) + 0.03, curvature = -0.2) +

  # slab fill
  label_(x = 5.5, y = 0.7,
    label = 'slab_fill = fill = "gray75"\nslab_alpha = alpha = 1\nslab_shape = 21',
    vjust = 1
  ) +
  arrow_(x = 5.48, xend = 4.81, y = 0.67, yend = thickness_(3.1) + 0.01, curvature = 0.2) +

  # xmin, x, xmax
  arrow_(x = 2.65, xend = 3, y = -0.1, yend = -0.01, curvature = -0.2) +
  label_(x = 2.7, y = -0.1, label = "xmin", hjust = 1, vjust = 1) +
  arrow_(x = 4, y = -0.1, yend = -0.05) +
  label_(x = 4, y = -0.1, label = "x", hjust = 0.5, vjust = 1) +
  arrow_(x = 5.35, xend = 5, y = -0.1, yend = -0.01, curvature = 0.2) +
  label_(x = 5.3, y = -0.1, label = "xmax", hjust = 0, vjust = 1) +

  # interval properties
  label_(x = 3.5, y = -0.2,
    label = paste0(
      'interval_color = color = "black"\n',
      'interval_alpha = alpha = 1\n',
      'interval_linetype = linetype = "solid"\n',
      'linewidth = size = 5'
    ),
    vjust = 1, hjust = 1
  ) +
  arrow_(x = 3.3, xend = 3.4, y = -0.18, yend = -0.015, curvature = -0.1) +

  # point properties
  label_(x = 4.5, y = -0.2,
    label = paste0(
      'point_fill = fill = "gray75"\n',
      'point_color = color = "black"\n',
      'point_alpha = alpha = 1\n',
      'point_size = size = 5\nshape = 22\nstroke = 1.5'
    ),
    vjust = 1, hjust = 0
  ) +
  arrow_(x = 4.55, xend = 4.2, y = -0.18, yend = -0.03, curvature = 0.2) +

  coord_cartesian(xlim = c(-1, 10), ylim = c(-0.6, 1)) +
  labs(subtitle = "Properties of geom_dotsinterval", x = NULL, y = NULL)

## ----dots_components, echo=FALSE, fig.height=3.04, fig.width=6.5----------------------------------
tibble(dist = dist_normal(4, 1.2)) %>%
  ggplot(aes(y = 0, xdist = dist)) +

  geom_hline(yintercept = 0:1, color = "gray95") +

  stat_dots(
    aes(linewidth = NULL),
    color = "gray50",
    fill = "gray75",
    linewidth = 1.5,
    shape = 21
  ) +

  # height
  refline_(x = 0, xend = 8.4, y = 1) +
  bracket_(x = 8.4, y = 0, yend = 1) +
  label_(label = "height", x = 8.6, y = 1) +

  # scale
  refline_(x = 4, xend = 8.6, y = 0.9) +
  bracket_(x = 8.6, y = 0, yend = 0.9) +
  label_(label = "scale = 0.9", x = 8.8, y = 0.9) +

  # slab line properties
  label_(x = 2.5, y = 0.7,
    label = 'color = "gray50"\nlinewidth = 1.5',
    vjust = 1, hjust = 1
  ) +
  arrow_(x = 2.52, xend = 3, y = 0.67, yend = thickness_(3.1) + 0.03, curvature = -0.2) +

  # slab fill
  label_(x = 5.5, y = 0.7,
    label = 'fill = "gray75"\nalpha = 1\nshape = 21',
    vjust = 1
  ) +
  arrow_(x = 5.48, xend = 4.81, y = 0.67, yend = thickness_(3.1) + 0.01, curvature = 0.2) +

  coord_cartesian(xlim = c(-1, 10), ylim = c(-0.05, 1)) +
  labs(subtitle = "Properties of geom_dots", x = NULL, y = NULL)

## ----layout_params, echo=FALSE, fig.height=3.7, fig.width=6---------------------------------------
data.frame(x = c(.4, .7, .7, 1, 1, 1)) %>%
  ggplot(aes(x = x)) +

  geom_hline(yintercept = 0:1, color = "gray95") +

  # binwidth
  refline_(x = seq(.25, 1.15, by = .3), y = -0.025, yend = 0.9, color = green_) +
  bracket_(x = .25, xend = .55, y = -0.025, color = green_) +
  label_(
    label = "binwidth = NA\n=> binwidth = 0.3\n(auto-selected so that\n the tallest stack is \u2264 scale)",
    x = 0.55, y = -0.08, vjust = 1, hjust = 1, color = green_
  ) +

  geom_dots(scale = 0.9, dotsize = 1, alpha = 0.5) +

  # height
  refline_(x = 0, xend = 2, y = 1) +
  bracket_(x = 2, y = 0, yend = 1) +
  label_(label = "height", x = 2.05, y = 1) +

  # scale
  refline_(x = 0.25, xend = 2.1, y = 0.9) +
  bracket_(x = 2.1, y = 0, yend = 0.9) +
  label_(label = "scale = 0.9", x = 2.15, y = 0.9) +

  # stackratio
  refline_(x = 1, xend = 1.3, y = c(.15, .45)) +
  bracket_(x = 1.3, y = .15, yend = .45) +
  label_(label = "stackratio = 1", x = 1.35, y = .3) +

  # dotsize
  refline_(x = c(.85, 1.15), y = 0.15, yend = -0.025, color = blue_, linetype = "22", alpha = 1) +
  bracket_(x = .85, xend = 1.15, y = -0.025, color = blue_) +
  label_(
    label = "dotsize = 1\n(relative to binwidth)",
    x = 0.85, y = -0.08, vjust = 1, hjust = 0, color = blue_
  ) +

  scale_x_continuous(limits = c(-0.1, 2.35)) +
  scale_y_continuous(limits = c(-0.35, 1)) +
  coord_fixed() +
  labs(subtitle = "Layout parameters for dots geoms", x = NULL, y = NULL)

## ----horizontal_side, fig.width = small_width, fig.height = small_width/2-------------------------
set.seed(1234)
x = rnorm(100)

side_plot = function(...) {
  expand.grid(
    x = x,
    side = c("topright", "both", "bottomleft"),
    stringsAsFactors = FALSE
  ) %>%
    ggplot(aes(side = side, ...)) +
    geom_dots() +
    facet_grid(~ side, labeller = "label_both") +
    labs(x = NULL, y = NULL) +
    theme(panel.border = element_rect(color = "gray75", fill = NA))
}
side_plot(x = x) +
  labs(title = "Horizontal geom_dots() with different values of side") +
  scale_y_continuous(breaks = NULL)

## ----vertical_side, fig.width = small_width, fig.height = small_width/2---------------------------
side_plot(y = x) +
  labs(title = "Vertical geom_dots() with different values of side") +
  scale_x_continuous(breaks = NULL)

## ----layout_top, fig.width = small_width, fig.height = small_height-------------------------------
layout_plot = function(layout, side, ...) {
  data.frame(
    x = x
  ) %>%
    ggplot(aes(x = x)) +
    geom_dots(layout = layout, side = side, stackratio = if (layout == "hex") 0.9 else 1) +
    labs(
      subtitle = paste0("layout = ", deparse(layout), if (layout == "hex") " with stackratio = 0.9"),
      x = NULL,
      y = NULL
    ) +
    scale_y_continuous(breaks = NULL) +
    theme(panel.border = element_rect(color = "gray75", fill = NA))
}

(layout_plot("bin", side = "top") + layout_plot("hex", side = "top")) /
  (layout_plot("weave", side = "top") + layout_plot("swarm", side = "top")) +
  plot_annotation(title = 'geom_dots() layouts with side = "top"')

## ----layout_both, fig.width = small_width, fig.height = small_height------------------------------
(layout_plot("bin", side = "both") + layout_plot("hex", side = "both")) /
  (layout_plot("weave", side = "both") + layout_plot("swarm", side = "both")) +
  plot_annotation(title = 'geom_dots() layouts with side = "both"')

## ----beeswarm_bin, fig.width = small_width, fig.height = small_height-----------------------------
set.seed(1234)

abc_df = tibble(
  value = rnorm(300, mean = c(1,2,3), sd = c(1,2,2)),
  abc = rep(c("a", "b", "c"), 100)
)

abc_df %>%
  ggplot(aes(x = abc, y = value)) +
  geom_dots(side = "both") +
  ggtitle('geom_dots(side = "both")')

## ----beeswarm_hex, fig.width = small_width, fig.height = small_height-----------------------------
abc_df %>%
  ggplot(aes(x = abc, y = value)) +
  geom_dots(side = "both", layout = "hex", stackratio = 0.92) +
  ggtitle('geom_dots(side = "both", layout = "hex")')

## ----geom_weave, fig.width = small_width, fig.height = small_height-------------------------------
set.seed(1234)

swarm_data = tibble(
  y = rnorm(300, c(1,4)),
  g = rep(c("a","b"), 150)
)

swarm_plot = swarm_data %>%
  ggplot(aes(x = g, y = y)) +
  geom_swarm(linewidth = 0, alpha = 0.75) +
  labs(title = "geom_swarm()")

weave_plot = swarm_data %>%
  ggplot(aes(x = g, y = y)) +
  geom_weave(linewidth = 0, alpha = 0.75) +
  labs(title = "geom_weave()")

swarm_plot + weave_plot

## ----beeswarm_dodge, fig.width = small_width, fig.height = small_height---------------------------
set.seed(12345)

abcc_df = tibble(
  value = rnorm(300, mean = c(1,2,3,4), sd = c(1,2,2,1)),
  abc = rep(c("a", "b", "c", "c"), 75),
  hi = rep(c("h", "h", "h", "i"), 75)
)

abcc_df %>%
  ggplot(aes(y = value, x = abc, fill = hi)) +
  geom_weave(position = "dodge", linewidth = 0, alpha = 0.75) +
  scale_fill_brewer(palette = "Dark2") +
  ggtitle(
    'geom_weave(position = "dodge")',
    'aes(fill = hi, shape = hi)'
  )

## ----beeswarm_shape_color_together, fig.width = small_width, fig.height = small_height------------
abcc_df %>%
  ggplot(aes(y = value, x = abc, fill = hi, group = NA)) +
  geom_dots(linewidth = 0) +
  scale_color_brewer(palette = "Dark2") +
  ggtitle(
    'geom_dots()',
    'aes(fill = hi, group = NA)'
  )

## ----beeswarm_shape_color_together_stacked, fig.width = small_width, fig.height = small_height----
abcc_df %>%
  ggplot(aes(y = value, x = abc, fill = hi, group = NA, order = hi)) +
  geom_dots(linewidth = 0) +
  scale_color_brewer(palette = "Dark2") +
  ggtitle(
    'geom_dots()',
    'aes(fill = hi, group = NA, order = hi)'
  )

## ----beeswarm_shape_color_continuous, fig.width = small_width, fig.height = small_height----------
abcc_df %>%
  arrange(hi) %>%
  ggplot(aes(y = value, x = abc, shape = abc, color = value)) +
  geom_dots() +
  ggtitle(
    'geom_dots()',
    'aes(color = value)'
  )

## ----increasing_samples, fig.width = med_width, fig.height = med_height---------------------------
set.seed(1234)

ns = c(50, 200, 500, 5000)
increasing_samples = data.frame(
  x = rgamma(sum(ns), 2, 2),
  n = rep(ns, ns)
)

increasing_samples %>%
  ggplot(aes(x = x)) +
  geom_dots() +
  facet_wrap(~ n) +
  labs(
    title = "geom_dots()",
    subtitle = "on large samples, dots may get too small"
  )

## ----increasing_samples_min_binwidth, fig.width = med_width, fig.height = med_height--------------
increasing_samples %>%
  ggplot(aes(x = x)) +
  geom_dots(binwidth = unit(c(1, Inf), "mm")) +
  facet_wrap(~ n) +
  labs(
    title = "geom_dots()",
    subtitle = 'binwidth = unit(c(1.5, Inf), "mm")'
  )

## ----increasing_samples_min_binwidth_compress, fig.width = med_width, fig.height = med_height-----
increasing_samples %>%
  ggplot(aes(x = x)) +
  geom_dots(binwidth = unit(c(1, Inf), "mm"), overflow = "compress", alpha = 0.75) +
  facet_wrap(~ n) +
  labs(
    title = "geom_dots()",
    subtitle = 'binwidth = unit(c(1, Inf), "mm"), overflow = "compress"'
  )

## ----discrete_dots_too_small, fig.width = small_width, fig.height = small_height------------------
set.seed(1234)
abcd_df = tibble(
  x = sample(c("a", "b", "c", "d"), 1000, replace = TRUE, prob = c(0.27, 0.6, 0.03, 0.005)),
  g = rep(c("a","b"), 500)
)

abcd_df %>%
  ggplot(aes(x = x)) +
  geom_dots() +
  scale_y_continuous(breaks = NULL) +
  labs(
    title = "geom_dots()",
    subtitle = "on a large discrete sample"
  )

## ----discrete_dots_bar, fig.width = small_width, fig.height = small_height------------------------
abcd_df %>%
  ggplot(aes(x = x, fill = g, order = g)) +
  geom_dots(layout = "bar", group = NA, color = NA) +
  scale_y_continuous(breaks = NULL) +
  labs(
    title = 'geom_dots(aes(fill = g), layout = "bar", group = NA)',
    subtitle = "on a large discrete sample"
  )

## ----discrete_dots_ep, fig.width = small_width, fig.height = small_height-------------------------
abcd_df %>%
  ggplot(aes(x = x)) +
  geom_dots(smooth = smooth_discrete(kernel = "ep"), side = "both") +
  scale_y_continuous(breaks = NULL) +
  labs(
    title = 'geom_dots(smooth = smooth_discrete(kernel = "ep"), side = "both")',
    subtitle = "on a large discrete sample"
  )

## ----dotsinterval_dist, fig.width = small_width, fig.height = small_height------------------------
dist_df = tibble(
  dist = c(dist_normal(1,0.25), dist_beta(3,3), dist_gamma(5,5)),
  dist_name = format(dist)
)

dist_df %>%
  ggplot(aes(y = dist_name, xdist = dist)) +
  stat_dotsinterval(subguide = 'integer') +
  ggtitle(
    "stat_dotsinterval(subguide = 'integer')",
    "aes(y = dist_name, xdist = dist)"
  )

## ----dotsinterval_dist_1000_level_color, fig.width = small_width, fig.height = small_height-------
dist_df %>%
  ggplot(aes(y = dist_name, xdist = dist, slab_fill = after_stat(level))) +
  stat_dotsinterval(quantiles = 1000, point_interval = mode_hdci, layout = "weave", slab_color = NA) +
  scale_color_manual(values = scales::brewer_pal()(3)[-1], aesthetics = "slab_fill") +
  ggtitle(
    "stat_dotsinterval(quantiles = 1000, point_interval = mode_hdci)",
    "aes(y = dist_name, xdist = dist, slab_fill = after_stat(level))"
  )

## ----dotsinterval_dist_color, fig.width = small_width, fig.height = small_height------------------
dist_df %>%
  ggplot(aes(y = dist_name, xdist = dist, slab_color = after_stat(x))) +
  stat_dotsinterval(slab_shape = 19, quantiles = 500) +
  scale_color_distiller(aesthetics = "slab_color", guide = "colorbar2") +
  ggtitle(
    "stat_dotsinterval(slab_shape = 19, quantiles = 500)",
    'aes(slab_color = after_stat(x)) +\nscale_color_distiller(aesthetics = "slab_color", guide = "colorbar2")'
  )

## ----dist_dots_weave, fig.width = small_width, fig.height = small_height--------------------------
ab_df = tibble(
  ab = c("a", "b"),
  mean = c(5, 7),
  sd = c(1, 1.5)
)

ab_df %>%
  ggplot(aes(y = ab, xdist = dist_normal(mean, sd), fill = after_stat(x < 6))) +
  stat_dots(position = "dodge", color = NA, layout = "weave") +
  labs(
    title = 'stat_dots(layout = "weave")',
    subtitle = "aes(fill = after_stat(x < 6))"
  ) +
  geom_vline(xintercept = 6, alpha = 0.25) +
  scale_x_continuous(breaks = 2:10)

## ----halfeye_dotplot, fig.width = small_width, fig.height = small_height--------------------------
set.seed(12345) # for reproducibility

tibble(
  abc = rep(c("a", "b", "b", "c"), 50),
  value = rnorm(200, c(1, 8, 8, 3), c(1, 1.5, 1.5, 1))
) %>%
  ggplot(aes(y = abc, x = value, fill = abc)) +
  stat_slab(aes(thickness = after_stat(pdf*n)), scale = 0.7) +
  stat_dotsinterval(side = "bottom", scale = 0.7, slab_linewidth = NA) +
  scale_fill_brewer(palette = "Set2") +
  ggtitle(
    paste0(
      'stat_slab(aes(thickness = after_stat(pdf*n)), scale = 0.7) +\n',
      'stat_dotsinterval(side = "bottom", scale = 0.7, slab_linewidth = NA)'
    ),
    'aes(fill = abc)'
  )

## ----mcse_blur_dots, fig.width=med_width, fig.height=med_height, warning=FALSE, eval=requireNamespace("posterior", quietly = TRUE) && getRversion() >= "4.1"----
increasing_samples %>%
  ggplot(aes(x = x)) +
  stat_mcse_dots(quantiles = 100) +
  facet_wrap(~ n) +
  labs(
    title = "stat_mcse_dots(quantiles = 100)",
    subtitle = "Monte Carlo Standard Error of each quantile shown as blur"
  )

## ----mcse_interval_dots, fig.width=med_width, fig.height=med_height, warning=FALSE, eval=requireNamespace("posterior", quietly = TRUE) && getRversion() >= "4.1"----
increasing_samples %>%
  ggplot(aes(x = x)) +
  stat_mcse_dots(quantiles = 100, blur = "interval") +
  facet_wrap(~ n) +
  labs(
    title = 'stat_mcse_dots(quantiles = 100, blur = "interval")',
    subtitle = "Monte Carlo Standard Error of each quantile shown as 95% intervals"
  )

## ----iris_v, fig.width = med_width, fig.height = med_height---------------------------------------
iris_v = iris %>%
  filter(Species != "setosa")

iris_v %>%
  ggplot(aes(x = Petal.Length, y = Species, side = Species)) +
  geom_dots(scale = 0.5) +
  scale_side_mirrored(guide = "none") +
  ggtitle(
    "geom_dots(scale = 0.5)",
    'aes(side = Species) + scale_side_mirrored()'
  )

## ----m_iris_v-------------------------------------------------------------------------------------
m = glm(Species == "virginica" ~ Petal.Length, data = iris_v, family = binomial)
m

## ----logit_dotplot, fig.width = med_width, fig.height = med_height/1.5----------------------------
# construct a prediction grid for the fit line
prediction_grid = with(iris_v,
  data.frame(Petal.Length = seq(min(Petal.Length), max(Petal.Length), length.out = 100))
)

prediction_grid %>%
  bind_cols(predict(m, ., se.fit = TRUE)) %>%
  mutate(
    # distribution describing uncertainty in log odds
    log_odds = dist_normal(fit, se.fit),
    # inverse-logit transform the log odds to get
    # distribution describing uncertainty in Pr(Species == "virginica")
    p_virginica = dist_transformed(log_odds, plogis, qlogis)
  ) %>%
  ggplot(aes(x = Petal.Length)) +
  geom_dots(
    aes(y = as.numeric(Species == "virginica"), side = Species),
    scale = 0.4,
    data = iris_v
  ) +
  stat_lineribbon(
    aes(ydist = p_virginica), alpha = 1/4, fill = "#08306b"
  ) +
  scale_side_mirrored(guide = "none") +
  coord_cartesian(ylim = c(0, 1)) +
  labs(
    title = "logit dotplot: geom_dots() with stat_lineribbon()",
    subtitle = 'aes(side = Species) + scale_side_mirrored()',
    x = "Petal Length",
    y = "Pr(Species = virginica)"
  )

## ----reset_options, include=FALSE---------------------------------------------
options(.old_options)

