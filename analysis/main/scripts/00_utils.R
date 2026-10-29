# Shared helpers for this analysis. run_all.R sources this first; each
# numbered step can also start with
#   source(file.path("analysis", "main", "scripts", "00_utils.R"))
# so that it runs on its own.

# Font-metric calculations (ggplot_build(), arrangeGrob(), ...) implicitly open
# the default pdf device under Rscript. Absorb it so no stray Rplots.pdf is left.
grDevices::pdf(NULL)

# renv is activated by the repo-root .Rprofile, so R must start there.
if (!file.exists("renv.lock") || !dir.exists(file.path("analysis", "main"))) {
  stop(
    "Run R from the repo root (e.g. `bin/r analysis/main/scripts/run_all.R`); ",
    "the working directory is ", getwd(),
    call. = FALSE
  )
}

# Paths, relative to the repo root. When copying this directory to
# analysis/<name>/, update ANALYSIS_DIR, the paths in run_all.R, and the
# source() line at the top of each step.
ANALYSIS_DIR <- file.path("analysis", "main")

path_raw       <- function(...) file.path("data", "raw", ...)
path_processed <- function(...) file.path("data", "processed", ...)
path_tables    <- function(...) file.path(ANALYSIS_DIR, "results", "tables", ...)
path_figures   <- function(...) file.path(ANALYSIS_DIR, "results", "figures", ...)

for (dir in c(path_processed(), path_tables(), path_figures())) {
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
}

# Save a plot to results/figures/ through ragg, which renders Unicode such as
# Δ / ± reliably. CJK text additionally needs a CJK font in the image
# (e.g. "fonts-noto-cjk" via the apt-packages feature).
# `plot` may be a ggplot, a grob (e.g. gridExtra::arrangeGrob()), or a
# function that draws with base graphics. Returns the file path invisibly.
save_plot <- function(plot, filename, width = 7, height = 5, units = "in",
                      res = 300, ...) {
  path <- path_figures(filename)
  ragg::agg_png(path, width = width, height = height, units = units,
                res = res, ...)
  on.exit(grDevices::dev.off(), add = TRUE)
  if (is.function(plot)) {
    plot()
  } else if (inherits(plot, "grob")) {
    grid::grid.newpage()
    grid::grid.draw(plot)
  } else {
    print(plot)
  }
  invisible(path)
}
