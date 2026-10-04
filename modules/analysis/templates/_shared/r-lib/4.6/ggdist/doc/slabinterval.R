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

## ----slabinterval_family, echo=FALSE, fig.height=5.5, fig.width=6.2-------------------------------
dists_df = tibble(
  # enforce order
  geom = rev(c(
    "halfeye",
    "eye",
    "gradientinterval",
    "ccdfinterval",
    "cdfinterval",
    "interval",
    "pointinterval",
    "slab",
    "histinterval",
    "dots",
    "dotsinterval"
  )) %>%
    factor(., levels = .),
  dist = dist_normal(4, 1)
)

hist_df = tibble(
  geom = "histinterval",
  x = qnorm(ppoints(1000), 4, 1)
)

dists_df_ = function(geom_) filter(dists_df, geom == geom_)


# FAMILY HEADER

dists_xlim = c(0,8)

header_theme = theme(
  axis.line.x = element_blank(),
  plot.background = element_rect(fill = "gray95"),
  panel.background = element_blank(),
  plot.margin = unit(c(5.5, 0, 5.5, 5.5), "points")
)

dists_header_plot = dists_df_("halfeye") %>%
  mutate(geom = "slabinterval") %>%
  ggplot(aes(y = geom, xdist = dist)) +
  stat_slabinterval(position = position_nudge(y = - 0.2)) +
  scale_x_continuous(limits = dists_xlim, expand = c(0,0), breaks = NULL) +
  scale_y_discrete(expand = c(0.4,0)) +
  labs(
    subtitle = "The stat_slabinterval / geom_slabinterval family",
    x = NULL,
    y = NULL
  ) +
  header_theme

statgeom_theme = list(
  labs(y = NULL, x = NULL),
  theme(
    axis.line.x = element_blank(),
    axis.line.y = element_blank(),
    axis.ticks = element_blank(),
    plot.margin = unit(c(5.5, 5.5, 5.5, 0), "points")
  )
)

statgeom_header_plot = data.frame(
  geom = factor("slabinterval"),
  prefix = factor(c("stat_...", "geom_..."), levels = c("stat_...", "geom_..."))
) %>%
  ggplot(aes(x = prefix, y = geom)) +
  geom_hline(aes(yintercept = as.numeric(geom) - .1), color = "gray80", data = . %>% filter(prefix == "stat_...")) +
  geom_point(size = 5, color = "gray65", position = position_nudge(y = -.1)) +
  scale_x_discrete(position = "top") +
  scale_y_discrete(breaks = NULL, expand = c(0.4,0)) +
  statgeom_theme +
  header_theme


# SHORTCUT STATS

dists_plot = dists_df %>%
  ggplot(aes(y = geom, xdist = dist)) +
  geom_blank() + # ensures order
  stat_eye(data = dists_df_("eye")) +
  stat_halfeye(data = dists_df_("halfeye"), position = position_nudge(y = -0.2)) +
  stat_gradientinterval(data = dists_df_("gradientinterval"), scale = .5, fill_type = "gradient") +
  stat_ccdfinterval(data = dists_df_("ccdfinterval"), scale = .5) +
  stat_cdfinterval(data = dists_df_("cdfinterval"), scale = .5) +
  stat_interval(
    data = dists_df_("interval"), color = "gray65", alpha = 1/3, linewidth = 10,
    position = position_nudge(y = -.1)
  ) +
  stat_pointinterval(data = dists_df_("pointinterval")) +
  stat_slab(data = dists_df_("slab"), position = position_nudge(y = - 0.2)) +
  stat_histinterval(aes(x = x, xdist = NULL), data = hist_df, position = position_nudge(y = - 0.25)) +
  stat_dotsinterval(data = dists_df_("dotsinterval"), position = position_nudge(y = - 0.35)) +
  stat_dots(data = dists_df_("dots"), position = position_nudge(y = - 0.35)) +
  scale_slab_alpha_continuous(guide = "none") +
  scale_x_continuous(limits = dists_xlim, expand = c(0,0)) +
  labs(
    x = NULL,
    y = NULL
  )

statgeom_plot = tribble(
  ~geom,                 ~prefix,
  "halfeye",            "stat_...",
  "eye",                "stat_...",
  "gradientinterval",   "stat_...",
  "ccdfinterval",       "stat_...",
  "cdfinterval",        "stat_...",
  "interval",         c("stat_...", "geom_..."),
  "pointinterval",    c("stat_...", "geom_..."),
  "slab",             c("stat_...", "geom_..."),
  "histinterval",       "stat_...",
  "dots",             c("stat_...", "geom_..."),
  "dotsinterval",     c("stat_...", "geom_...")
) %>%
  unnest(prefix) %>%
  mutate(
    geom = factor(geom, levels = levels(dists_df$geom)),
    prefix = factor(prefix, levels = c("stat_...", "geom_..."))
  ) %>%
  ggplot(aes(x = prefix, y = geom)) +
  geom_hline(aes(yintercept = as.numeric(geom) - .1), color = "gray80", data = . %>% filter(prefix == "stat_...")) +
  geom_point(size = 5, color = "gray65", position = position_nudge(y = -.1)) +
  scale_x_discrete(breaks = NULL) +
  scale_y_discrete(breaks = NULL, expand = c(0,.6)) +
  statgeom_theme

dists_header_plot + statgeom_header_plot +
  dists_plot + statgeom_plot +
  plot_layout(ncol = 2, widths = c(0.75, 0.25), heights = c(1, 10))

## ----slabinterval_components, echo=FALSE, fig.height=4.2, fig.width=6.5---------------------------
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
thickness_bracket_ = function(x) bracket_(x = x, y = 0, yend = thickness_(x))
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


dists_df_("halfeye") %>%
  ggplot(aes(y = 0, xdist = dist)) +
  stat_slabinterval(
    aes(linewidth = NULL),
    slab_color = "black",
    expand = FALSE,
    limits = c(0, 8),
    .width = 1 - 2*pnorm(-1),
    fill = "gray75",
    point_size = 3,
    shape = 21,
    stroke = 1.5,
    linewidth = 3
  ) +

  # height
  refline_(x = 0, xend = 8.4, y = 1) +
  bracket_(x = 8.4, y = 0, yend = 1) +
  label_(label = "height", x = 8.6, y = 1) +

  # scale
  refline_(x = 4, xend = 8.6, y = 0.9) +
  bracket_(x = 8.6, y = 0, yend = 0.9) +
  label_(label = "scale = 0.9", x = 8.8, y = 0.9) +

  # thickness
  thickness_bracket_(2) +
  thickness_bracket_(2.2) +
  thickness_bracket_(2.4) +
  label_(label = "thickness", hjust = 1, x = 1.63, y = thickness_(2.2), vjust = 0) +
  arrow_(curvature = 0.2, x = 1.67, xend = 1.87, y = thickness_(2.2), yend = thickness_(2) + 0.01) +
  arrow_(x = 1.67, xend = 2.07, y = thickness_(2.2) + 0.01, yend = thickness_(2.2)) +
  arrow_(curvature = -0.2, x = 1.67, xend = 2.27, y = thickness_(2.2) + 0.02, yend = thickness_(2.4)) +

  # slab line properties
  label_(x = 2.5, y = 0.7,
    label = 'slab_color = "black"\nslab_linewidth = 1\nslab_linetype = linetype = "solid"',
    vjust = 1, hjust = 1
  ) +
  arrow_(x = 2.52, xend = 3.08, y = 0.67, yend = thickness_(3.08) + 0.03, curvature = -0.2) +

  # slab fill
  label_(x = 5.5, y = 0.7,
    label = 'slab_fill = fill = "gray75"\nslab_alpha = alpha = 1',
    vjust = 1
  ) +
  arrow_(x = 5.48, xend = 4.5, y = 0.67, yend = thickness_(3), curvature = 0.2) +

  # xmin, x, xmax
  arrow_(x = 2.65, xend = 3, y = -0.1, yend = -0.01, curvature = -0.2) +
  label_(x = 2.7, y = -0.1, label = "xmin", hjust = 1, vjust = 1) +
  arrow_(x = 4, y = -0.1, yend = -0.04) +
  label_(x = 4, y = -0.1, label = "x", hjust = 0.5, vjust = 1) +
  arrow_(x = 5.35, xend = 5, y = -0.1, yend = -0.01, curvature = 0.2) +
  label_(x = 5.3, y = -0.1, label = "xmax", hjust = 0, vjust = 1) +

  # interval properties
  label_(x = 3.5, y = -0.2,
    label = paste0(
      'interval_color = color = "black"\n',
      'interval_alpha = alpha = 1\n',
      'interval_linetype = linetype = "solid"\n',
      'linewidth = size = 3'
    ),
    vjust = 1, hjust = 1
  ) +
  arrow_(x = 3.3, xend = 3.4, y = -0.18, yend = -0.01, curvature = -0.1) +

  # point properties
  label_(x = 4.5, y = -0.2,
    label = paste0(
      'point_fill = fill = "gray75"\n',
      'point_color = color = "black"\n',
      'point_alpha = alpha = 1\n',
      'point_size = size = 3\n',
      'shape = 21\n',
      'stroke = 1.5'
    ),
    vjust = 1, hjust = 0
  ) +
  arrow_(x = 4.55, xend = 4.12, y = -0.18, yend = -0.02, curvature = 0.2) +

  coord_cartesian(xlim = c(-1, 10), ylim = c(-0.6, 1)) +
  labs(subtitle = "Properties of geom_slabinterval")

## ----sample_data----------------------------------------------------------------------------------
set.seed(1234)
df = tribble(
  ~group, ~subgroup, ~value,
  "a",          "h", rnorm(1000, mean = 5),
  "b",          "h", rnorm(1000, mean = 7, sd = 1.5),
  "c",          "h", rnorm(1000, mean = 8),
  "c",          "i", rnorm(1000, mean = 9),
  "c",          "j", rnorm(1000, mean = 7)
) %>%
  unnest(value)

## ----group_halfeye, fig.width = tiny_height, fig.height = tiny_height-----------------------------
df %>%
  ggplot(aes(y = group, x = value)) +
  stat_halfeye() +
  ggtitle("stat_halfeye() (or stat_slabinterval())")

## ----eye_side, fig.width = med_width, fig.height = small_height-----------------------------------
p = df %>%
  ggplot(aes(x = group, y = value)) +
  theme(panel.background = element_rect(color = "grey70"))

(
  p + stat_slabinterval(side = "left") +
    labs(title = "stat_slabinterval()", subtitle = "side = 'left'")
) + (
  p + stat_slabinterval(side = "both") +
    labs(subtitle = "side = 'both'")
) + (
  p + stat_slabinterval(side = "right") +
    labs(subtitle = "side = 'right'")
)

## ----eyeh_side, fig.width = med_width, fig.height = small_height----------------------------------
p = df %>%
  ggplot(aes(x = value, y = group)) +
  theme(panel.background = element_rect(color = "grey70"))

(
  # side = "left" would give the same result
  p + stat_slabinterval(side = "left") +
    ggtitle("stat_slabinterval()") + labs(subtitle = "side = 'bottom'")
) + (
  p + stat_slabinterval(side = "both") + labs(subtitle = "side = 'both'")
) + (
  # side = "right" would give the same result
  p + stat_slabinterval(side = "right") + labs(subtitle = "side = 'top'")
)

## ----eye_dodge------------------------------------------------------------------------------------
df %>%
  ggplot(aes(x = group, y = value, fill = subgroup)) +
  stat_eye(position = "dodge") +
  ggtitle("stat_eye(position = 'dodge')")

## ----dist_data------------------------------------------------------------------------------------
dist_df = tribble(
  ~group, ~subgroup, ~mean, ~sd,
  "a",          "h",     5,   1,
  "b",          "h",     7,   1.5,
  "c",          "h",     8,   1,
  "c",          "i",     9,   1,
  "c",          "j",     7,   1
)

## ----dist_eye_dodge_distributional----------------------------------------------------------------
dist_df %>%
  ggplot(aes(x = group, ydist = dist_normal(mean, sd), fill = subgroup)) +
  stat_eye(position = "dodge") +
  ggtitle("stat_eye(position = 'dodge')", "aes(ydist = dist_normal(mean, sd))")

## ----beta_stacked---------------------------------------------------------------------------------
data.frame(alpha = seq(5, 100, length.out = 10)) %>%
  ggplot(aes(y = alpha, xdist = dist_beta(alpha, 10))) +
  stat_halfeye() +
  labs(
    title = "stat_halfeye()",
    subtitle = "aes(xdist = dist_beta(alpha, 10), y = alpha)",
    x = "Beta(alpha,10) distribution"
  )

## ----beta_overplotted_slabh-----------------------------------------------------------------------
data.frame(alpha = seq(5, 100, length.out = 10)) %>%
  ggplot(aes(xdist = dist_beta(alpha, 10), color = alpha)) +
  stat_slab(fill = NA) +
  coord_cartesian(expand = FALSE) +
  scale_color_viridis_c() +
  labs(
    title = "stat_slab()",
    subtitle = "aes(xdist = dist_beta(alpha, 10), color = alpha)",
    x = "Beta(alpha,10) distribution",
    y = NULL
  )

## ----priors_fake, eval=FALSE----------------------------------------------------------------------
# # NB these priors are made up!
# priors = c(
#   prior(normal(1, 0.5), class = b),
#   prior(gamma(2, 2), class = phi),
#   # lb = 0 sets a lower bound of 0, i.e. a half-Normal distribution
#   prior(normal(0, 1), class = sigma, lb = 0)
# )
# priors

## ----priors, echo=FALSE---------------------------------------------------------------------------
# we want to avoid a brms dependency, so we fake it above and
# just show the output of brms::prior() here
priors = data.frame(
  prior = c("normal(1, 0.5)", "gamma(2, 2)", "normal(0, 1)"),
  class = c("b", "phi", "sigma"),
  coef = c("", "", ""),
  group = c("", "", ""),
  resp = c("", "", ""),
  dpar = c("", "", ""),
  nlpar = c("", "", ""),
  lb = c(NA, NA, "0"),
  ub = c(NA, NA, NA),
  stringsAsFactors = FALSE
)
priors

## ----parse_dist-----------------------------------------------------------------------------------
priors %>%
  parse_dist(prior)

## ----prior_dist_halfeyeh--------------------------------------------------------------------------
priors %>%
  parse_dist(prior) %>%
  ggplot(aes(y = paste(class, "~", format(.dist_obj)), xdist = .dist_obj)) +
  stat_halfeye(subguide = subguide_inside(position = "right", title = "density")) +
  labs(
    title = "stat_halfeye()",
    subtitle = "with parse_dist() and brms::prior() to show priors",
    x = NULL,
    y = NULL
  )

## ----prior_post, fig.width = med_width, fig.height = small_height * 2/3---------------------------
prior_post = data.frame(
  prior = dist_normal(0, 1),
  posterior = dist_normal(0.1, 0.5)
)

separate_scale_plot = prior_post %>%
  ggplot() +
  stat_halfeye(aes(xdist = posterior)) +
  stat_slab(aes(xdist = prior), fill = NA, color = "red") +
  labs(
    subtitle = "default: no shared thickness scale"
  )

shared_scale_plot = prior_post %>%
  ggplot() +
  stat_halfeye(aes(xdist = posterior)) +
  stat_slab(aes(xdist = prior), fill = NA, color = "#e41a1c") +
  scale_thickness_shared() +
  labs(subtitle = "with scale_thickness_shared()")

separate_scale_plot + shared_scale_plot + plot_annotation(title = "prior (slab) + posterior (halfeye)")

## ----dist_halfeyeh_log_scale, fig.width = small_height, fig.height = small_height/1.75------------
data.frame(dist = dist_lognormal(log(10), 2*log(10))) %>%
  ggplot(aes(xdist = dist)) +
  stat_halfeye() +
  scale_x_log10(breaks = 10^seq(-5,7, by = 2))

## ----stat_histinterval_horizontal, fig.width = med_width, fig.height = small_height---------------
p = df %>%
  ggplot(aes(x = group, y = value)) +
  theme(panel.background = element_rect(color = "grey70"))

ph = df %>%
  ggplot(aes(y = group, x = value)) +
  theme(panel.background = element_rect(color = "grey70"))

(
  p + stat_histinterval() + labs(title = "stat_histinterval()", subtitle = "horizontal")
) + (
  ph + stat_histinterval() + labs(subtitle = "vertical")
)

## ----stat_histintervalh_outlines, fig.width = med_width, fig.height = small_height----------------
(
  ph + stat_histinterval(slab_color = "gray45", outline_bars = FALSE) +
    labs(title = "stat_histinterval", subtitle = "outline_bars = FALSE (default)")
) + (
  ph + stat_histinterval(slab_color = "gray45", outline_bars = TRUE) +
    labs(subtitle = "outline_bars = TRUE")
)

## ----dist_slab_discrete, fig.width = med_width, fig.height = small_height-------------------------
tibble(
  group = c("a","b","c","d","e"),
  lambda = c(13,7,4,3,2)
) %>%
  ggplot(aes(x = group)) +
  stat_slab(aes(ydist = dist_poisson(lambda), fill = after_stat(pdf))) +
  geom_line(aes(y = lambda, group = NA), linewidth = 1) +
  geom_point(aes(y = lambda), size = 2.5) +
  labs(fill = "Pr(y)") +
  ggtitle("stat_slab()", "aes(ydist = dist_poisson(lambda), fill = after_stat(pdf))")

## ----ccdf_barplot---------------------------------------------------------------------------------
df %>%
  ggplot(aes(x = group, y = value, fill = subgroup, group = subgroup)) +
  stat_ccdfinterval(position = "dodge") +
  ggtitle("stat_ccdfinterval(position = 'dodge')")

## ----ccdf_justification---------------------------------------------------------------------------
df %>%
  ggplot(aes(x = group, y = value, fill = subgroup)) +
  stat_ccdfinterval(position = "dodge", justification = 1) +
  expand_limits(y = 0) +
  coord_cartesian(expand = FALSE) +
  ggtitle("stat_ccdfinterval(position = 'dodge', justification = 1)")

## ----gradient_dodge-------------------------------------------------------------------------------
df %>%
  ggplot(aes(x = group, y = value, fill = subgroup)) +
  stat_gradientinterval(position = "dodge") +
  labs(title = "stat_gradientinterval(position = 'dodge')")

## ----gradient_dodge_nice--------------------------------------------------------------------------
df %>%
  ggplot(aes(x = group, y = value, fill = subgroup)) +
  stat_gradientinterval(position = "dodge", fill_type = "gradient") +
  labs(title = "stat_gradientinterval(position = 'dodge', fill_type = 'gradient')")

## ----dots_dodge_nocolor, fig.width = med_width, fig.height = small_height-------------------------
df %>%
  ggplot(aes(x = group, y = value, fill = subgroup, color = subgroup)) +
  stat_dots(position = "dodgejust") +
  labs(
    title = "stat_dots()",
    subtitle = "aes(fill = subgroup, color = subgroup))"
  )

## ----quantile_dots_dodge, fig.width = med_width, fig.height = small_height------------------------
df %>%
  ggplot(aes(x = group, y = value, fill = subgroup)) +
  stat_dots(position = "dodgejust", quantiles = 50, color = NA) +
  labs(title = "stat_dots(quantiles = 50)")

## ----ccdf_gradient, fig.width = med_width, fig.height = small_height------------------------------
df %>%
  ggplot(aes(x = group, y = value, fill = subgroup)) +
  stat_ccdfinterval(aes(slab_alpha = after_stat(f)),
    thickness = 1, position = "dodge", fill_type = "gradient"
  ) +
  expand_limits(y = 0) +
  # plus coord_cartesian so there is no space between bars and axis
  coord_cartesian(expand = FALSE) +
  ggtitle("stat_ccdfinterval(thickness = 1)", "aes(slab_alpha = after_stat(f))")

## ----norm_vs_t_highlight, fig.width = small_width, fig.height = small_height----------------------
priors = tibble(
  dist = c(dist_normal(0, 1), dist_student_t(3, 0, 1))
)

priors %>%
  ggplot(aes(y = format(dist), xdist = dist)) +
  stat_halfeye(aes(fill = after_stat(abs(x) < 1.5))) +
  ggtitle("stat_halfeye()", "aes(fill = after_stat(abs(x) < 1.5)))") +
  # we'll use a nicer palette than the default for highlighting:
  scale_fill_manual(values = c("gray85", "skyblue"))

## ----norm_vs_t_gradient_eye, fig.width = small_width, fig.height = small_height-------------------
priors %>%
  ggplot(aes(y = format(dist), xdist = dist)) +
  stat_eye(aes(slab_alpha = after_stat(f), fill = after_stat(x > 1)), fill_type = "gradient") +
  ggtitle(
    "stat_eye(fill_type = 'gradient')",
    "aes(slab_alpha = after_stat(f), fill = after_stat(x > 1)))"
  ) +
  # we'll use a nicer palette than the default for highlighting:
  scale_fill_manual(values = c("gray75", "skyblue"))

## ----correll_gradient, fig.width = small_width, fig.height = small_height/1.75--------------------
priors %>%
  ggplot(aes(y = format(dist), xdist = dist)) +
  stat_gradientinterval(aes(slab_alpha = after_stat(-pmax(abs(1 - 2*cdf), .95))),
    fill_type = "gradient"
  ) +
  scale_slab_alpha_continuous(guide = "none") +
  ggtitle(
    "stat_gradientinterval(fill_type = 'gradient')",
    "aes(slab_alpha = after_stat(-pmax(abs(1 - 2*cdf), .95)))"
  )

## ----helske_gradient_eye, fig.width = small_width, fig.height = small_height----------------------
priors %>%
  ggplot(aes(y = format(dist), xdist = dist)) +
  stat_eye(aes(slab_alpha = after_stat(-pmax(abs(1 - 2*cdf), .95))), fill_type = "gradient") +
  scale_slab_alpha_continuous(guide = "none") +
  ggtitle(
    "stat_eye(fill_type = 'gradient')",
    "aes(slab_alpha = after_stat(-pmax(abs(1 - 2*cdf), .95)))"
  )

## ----tukey_pencils, fig.width = small_width, fig.height = small_height----------------------------
dist_df %>%
  ggplot(aes(x = group, ydist = dist_normal(mean, sd), fill = subgroup)) +
  stat_slab(
    aes(
      thickness = after_stat(pmax(0, abs(1 - 2*cdf) - .95)),
      fill_ramp = after_stat(pmax(0, abs(1 - 2*cdf) - .95))
    ),
    side = "both", position = "dodge", fill_type = "gradient"
  ) +
  labs(
    title = 'stat_slab(side = "both")',
    subtitle = paste0(
      "aes(fill = subgroup,\n       ",
      "fill_ramp and thickness = after_stat(pmax(0, abs(1 - 2*cdf) - .95)))"
    )
  ) +
  guides(fill_ramp = "none") +
  coord_cartesian(expand = FALSE)

## ----halfeye_filled_intervals, fig.width = small_width, fig.height = small_height-----------------
df %>%
  ggplot(aes(y = group, x = value)) +
  stat_halfeye(aes(fill = after_stat(level))) +
  # na.translate = FALSE drops the unnecessary NA from the legend, which covers
  # slab values outside the intervals. An alternative would be to use
  # na.value = ... to set the color for values outside the intervals.
  scale_fill_brewer(na.translate = FALSE) +
  labs(
    title = "stat_halfeye()",
    subtitle = "aes(fill = after_stat(level))",
    fill = "interval"
  )

## ----halfeye_filled_intervals_2, fig.width = small_width, fig.height = small_height---------------
df %>%
  ggplot(aes(y = group, x = value)) +
  stat_slab(aes(fill = after_stat(level)), .width = c(.66, .95, 1)) +
  stat_pointinterval() +
  scale_fill_brewer() +
  labs(
    title = "stat_slab()",
    subtitle = "aes(fill = after_stat(level), .width = c(.66, .95, 1))",
    fill = "interval"
  )

## ----halfeye_qi_vs_hdi, fig.width = small_width, fig.height = small_height------------------------
qi_plot = data.frame(dist = dist_beta(10, 2)) %>%
  ggplot(aes(xdist = dist)) +
  stat_halfeye(aes(fill = after_stat(level)), point_interval = median_qi, .width = c(.5, .8, .95)) +
  scale_fill_brewer(na.value = "gray95") +
  labs(subtitle = "stat_halfeye(aes(fill = after_stat(level)), point_interval = median_qi)")

hdi_plot = data.frame(dist = dist_beta(10, 2)) %>%
  ggplot(aes(xdist = dist)) +
  stat_halfeye(aes(fill = after_stat(level)), point_interval = mode_hdci, .width = c(.5, .8, .95)) +
  scale_fill_brewer(na.value = "gray95") +
  labs(subtitle = "stat_halfeye(aes(fill = after_stat(level)), point_interval = mode_hdci)")

qi_plot /
  hdi_plot

## ----halfeye_qi_vs_hdi_spikes, fig.width = small_width, fig.height = small_height-----------------
qi_plot_spikes = data.frame(dist = dist_beta(10, 2)) %>%
  ggplot(aes(xdist = dist)) +
  stat_slab(aes(fill = after_stat(level)), point_interval = median_qi, .width = c(.5, .95)) +
  # stat_spike(at = c(median, qi)) would also work, but this demonstrates how
  # to re-label the names of the `at` computed variable and use it in an
  # aesthetic mapping by mapping it to `linetype`
  stat_spike(aes(linetype = after_stat(at)), at = c("median", "interval (qi)" = qi)) +
  scale_fill_brewer(na.value = "gray95") +
  scale_thickness_shared() +
  labs(subtitle = "stat_slab() + stat_spike(at = c(median, qi))")

hdi_plot_spikes = data.frame(dist = dist_beta(10, 2)) %>%
  ggplot(aes(xdist = dist)) +
  stat_slab(aes(fill = after_stat(level)), point_interval = mode_hdi, .width = c(.5, .95)) +
  stat_spike(aes(linetype = after_stat(at)), at = c("mode" = Mode, "interval (hdi)" = hdi)) +
  scale_fill_brewer(na.value = "gray95") +
  scale_thickness_shared() +
  labs(subtitle = "stat_slab() + stat_spike(at = c(Mode, hdi))")

qi_plot_spikes /
  hdi_plot_spikes

## ----halfeye_filled_intervals_subgroup, fig.width = small_width, fig.height = small_height--------
df %>%
  ggplot(aes(y = group, x = value)) +
  stat_halfeye(
    aes(fill = subgroup, fill_ramp = after_stat(level)),
    .width = c(.50, .80, .95),
    # NOTE: we use position = "dodgejust" (a dodge that respects the
    # justification of intervals relative to slabs) instead of
    # position = "dodge" here because it ensures the topmost slab does
    # not extend beyond the plot limits
    position = "dodgejust"
  ) +
  # a range from 1 down to 0.2 ensures the fill goes dark to light inside-out
  # and doesn't get all the way down to white (0) on the lightest color
  scale_fill_ramp_discrete(na.translate = FALSE) +
  labs(
    title = "stat_halfeye(position = 'dodgejust')",
    subtitle = "aes(fill = subgroup, fill_ramp = after_stat(level))",
    fill_ramp = "interval"
  )

## ----dist_interval_color_ramp, fig.width = small_width, fig.height = small_height-----------------
dist_df %>%
  ggplot(aes(x = group, ydist = dist_normal(mean, sd), color = subgroup)) +
  stat_interval(aes(color_ramp = after_stat(level)), position = "dodge") +
  labs(
    title = "stat_interval()",
    subtitle = "aes(color = subgroup, color_ramp = after_stat(level))"
  )

## ----raindrop, fig.width = small_width, fig.height = small_height/1.5-----------------------------
priors %>%
  ggplot(aes(y = format(dist), xdist = dist)) +
  # must also use normalize = "groups" because min(log(pdf)) will be different for each dist
  stat_slab(
    aes(thickness = after_stat(ifelse(.width <= 0.99, log(pdf), NA))),
    normalize = "groups", fill = "gray85", .width = .99, side = "both"
  ) +
  stat_eye(
    aes(thickness = after_stat(ifelse(.width <= 0.95, log(pdf), NA))),
    normalize = "groups"
  ) +
  ggtitle(
    'stat_eye(normalize = "groups")',
    paste0(
      "with aes(thickness = after_stat(ifelse(.width <= 0.95, log(pdf), NA)))\n",
      "and aes(thickness = after_stat(ifelse(.width <= 0.99, log(pdf), NA)))"
    )
  )

## ----slab_ridge, fig.width = small_width, fig.height = small_height-------------------------------
set.seed(1234)

ridges_df = data.frame(
  group = letters[7:1],
  x = rnorm(700, mean = 1:7, sd = 2)
)

ridges_df %>%
  ggplot(aes(y = group, x = x)) +
  stat_slab(height = 2, color = "black") +
  ggtitle("stat_slab(height = 2, color = 'black')")

## ----slab_ridge_ramp, fig.width = small_width, fig.height = small_height--------------------------
ridges_df %>%
  ggplot(aes(
    y = group, x = x,
    fill = group, fill_ramp = after_stat(abs(x)),
    color_ramp = after_stat(-dnorm(x, 0, 2))
  )) +
  stat_slab(
    height = 2, color = "gray15",
    expand = TRUE, trim = FALSE, density = "unbounded",
    fill_type = "gradient",
    show.legend = FALSE
  ) +
  geom_vline(xintercept = 0, color = "gray85", linetype = "dashed") +
  ggtitle(
    'stat_slab(height = 2, color = "black", expand = TRUE, trim = FALSE)',
    'aes(fill = group, fill_ramp = after_stat(abs(x)), color_ramp = after_stat(-dnorm(x, 0, 2)))'
  ) +
  scale_fill_viridis_d()

## ----varying_side_dotplot, fig.width = small_width, fig.height = small_height---------------------
dist_df %>%
  filter(subgroup == "h") %>%
  mutate(side = c("top", "both", "bottom")) %>%
  ggplot(aes(y = group, xdist = dist_normal(mean, sd), side = side)) +
  stat_dotsinterval(scale = 2/3) +
  labs(
    title = 'stat_dotsinterval(scale = 2/3)',
    subtitle = 'aes(xdist = dist_normal(mean, sd), side = c("top","both","bottom"))'
  ) +
  coord_cartesian()

## ----halfeye_quantile_dotplot, fig.width = small_width, fig.height = small_height-----------------
df %>%
  ggplot(aes(x = group, y = value, fill = subgroup)) +
  stat_slab(side = "left", scale = 0.5, position = "dodge") +
  stat_dotsinterval(scale = 0.5, quantiles = 100, position = "dodge") +
  stat_pointinterval(
    geom = "label",
    aes(label = paste0(group, subgroup)),
    .width = .5,  # set to a scalar to draw only one label instead of two
    position = position_dodge(width = 1),
    size = 3.5
  ) +
  labs(title = paste0(
    'stat_halfeye(side = "left") +\n',
    'stat_dotsinterval(quantiles = 100) +\n',
    'stat_pointinterval(geom = "label")'
  ))

## ----slab_and_pointinterval, fig.width = small_width, fig.height = small_height/1.25--------------
df %>%
  ggplot(aes(fill = group, color = group, x = value)) +
  stat_slab(alpha = .3) +
  stat_pointinterval(position = position_dodgejust(width = .2), justification = 0.1) +
  labs(
    title = "stat_slab() and stat_pointinterval()",
    subtitle = "with position_dodgejust() applied to the intervals",
    y = NULL
  ) +
  scale_y_continuous(breaks = NULL)

## ----reset_options, include=FALSE---------------------------------------------
options(.old_options)

