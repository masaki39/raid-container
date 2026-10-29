# Run the whole pipeline from the repo root:
#   bin/r analysis/main/scripts/run_all.R
# Sources 00_utils.R, then every numbered step (01_*.R, 02_*.R, ...) in order.

scripts_dir <- file.path("analysis", "main", "scripts")
source(file.path(scripts_dir, "00_utils.R"))

steps <- sort(list.files(scripts_dir, pattern = "^[0-9]+_.*\\.R$"))
steps <- setdiff(steps, "00_utils.R")

for (step in steps) {
  message("==> ", step)
  source(file.path(scripts_dir, step))
}

message("Done: ", length(steps), " step(s) run.")
