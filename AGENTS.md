# Overview

This repository ships with a Rocker-based dev container (`ghcr.io/rocker-org/devcontainer/tidyverse`) so you can run R out of the box. You (the agent) run on the **host** and drive R inside the container through `bin/r` (a thin wrapper around `docker exec`).

# Container Startup

If VS Code is not driving the container (e.g. host is macOS + Colima), bring it up yourself:

```zsh
# 1. Start the Docker daemon (skip if already running)
colima start

# 2. Bring up the dev container (run from the repo root)
devcontainer up --workspace-folder .
#   `pnpm dlx @devcontainers/cli up --workspace-folder .` also works if the CLI is not installed
```

- `postCreateCommand` runs `renv::restore(prompt = FALSE)` when the container is created, so packages are ready once `devcontainer up` returns.
- An already-running container is reused by `devcontainer up`; restart a stopped one with `docker start <containerId>`.
- The renv cache is persisted in a Docker volume shared by all dev containers, so later restores mostly link from the cache.
- **Apple Silicon**: the tidyverse image is published for `linux/amd64` only and runs under emulation, so the first build and source-package installs are slow. Colima can also emulate through Rosetta (`colima start --vm-type vz --vz-rosetta`), which may be faster; this changes the VM settings and was not measured for this template.

# Running R

Use `bin/r` from the repo root. It finds this folder's dev container, then runs `Rscript` with your arguments inside it, from the repo root, as `rstudio` (the container's `remoteUser`, the same user as `postCreateCommand`).

```zsh
# Run the whole pipeline
bin/r analysis/main/scripts/run_all.R

# Run a one-liner
bin/r -e 'cat(R.version$version.string)'

# Check that the library matches renv.lock
bin/r -e 'renv::status()'
```

- Set `RAID_USER` to run as another user (e.g. `RAID_USER=root bin/r ...`). Avoid it for installs: root-owned files in `renv/library/` or the shared `/renv/cache` volume cannot be updated by `rstudio` later.
- Without the wrapper, the equivalent raw command is:

  ```zsh
  CID=$(docker ps -q --filter "label=devcontainer.local_folder=$PWD")
  docker exec -u rstudio -w "/workspaces/$(basename "$PWD")" "$CID" Rscript analysis/main/scripts/run_all.R
  ```

  `devcontainer.json` pins `workspaceFolder` to `/workspaces/<repo-name>`, so the repo root inside the container is always that path.

# Packages (renv)

- The project library is isolated by renv: R sees only `renv/library/` and the base/recommended packages. The tidyverse packages baked into the image (`/usr/local/lib/R/site-library`) are **not** visible, so every package an analysis uses must be installed through renv and recorded in `renv.lock`.
- The template's `renv.lock` contains `renv` plus `ragg` (and its dependencies) for `save_plot()` in `00_utils.R`.
- To add a package:

  ```zsh
  bin/r -e 'renv::install("dplyr")'
  # ... use it in a script (library(dplyr) or dplyr::), then:
  bin/r -e 'renv::snapshot(prompt = FALSE)'
  bin/r -e 'renv::status()'   # should report a consistent state
  ```

- `snapshot.type` is `implicit`: `renv::snapshot()` records only packages referenced in the project's R code (`library()`, `pkg::`, `requireNamespace()`, …). A package that is installed but not yet used in any script is **not** recorded, so write the code first, then snapshot. Conversely, `renv::status()` flags packages that scripts use but the library lacks.
- Binary packages come from Posit Package Manager (`p3m.dev`), so most installs are quick. Add system libraries needed by source builds (e.g. `libxml2-dev`) to the `apt-packages` feature in `.devcontainer/devcontainer.json`; never install R packages through apt.
- When upgrading R, bump the image tag in `devcontainer.json` and re-snapshot `renv.lock` in the new container together. CI fails if the R version in `renv.lock` differs from the image's R.

# Execution Rules

- **Always run R from the repo root** (`/workspaces/<repo-name>`). `renv` is activated by the root `.Rprofile`, so starting R in a sub-directory loses the project library. `bin/r` does this for you; write script paths relative to the root (`analysis/main/scripts/01_foo.R`), and build file paths with `file.path()` from the root (never assume the CWD is the script's directory).
- Write analyses as `.R` scripts rather than R Markdown.
- Rely on scripts for reproducibility: anything under `data/processed/` or `results/figures/` must be regenerable by `run_all.R`.
- When an analysis milestone is reached, create a git commit to save the state.

# Repository Layout

```
analysis/              independent analyses
├─ main/               the production pipeline (final deliverable)
│  ├─ scripts/         00_utils.R + numbered steps (01_, 02_, …) + run_all.R
│  ├─ results/
│  │  ├─ tables/       generated .csv (tracked in git)
│  │  └─ figures/      generated images (git-ignored)
│  └─ README.md        intent, inputs, steps, outputs, and results
└─ <name>/             exploratory / one-off analyses, same internal shape
bin/r                  run Rscript inside the dev container
data/
├─ raw/                source datasets (immutable; contents git-ignored)
└─ processed/          derived datasets (reproducible from scripts; contents git-ignored)
```

- `analysis/main/` holds the settled pipeline. Promote code here once it is confirmed in an exploratory directory.
- Give each analysis directory its own `README.md` and number the scripts so the run order is explicit. `run_all.R` sources `00_utils.R` and then every `NN_*.R` step in order; it succeeds even when there are no steps yet.
- Start each step with `source(file.path("analysis", "main", "scripts", "00_utils.R"))` so it can also run on its own. `00_utils.R` checks that R runs from the repo root, provides `path_raw()`, `path_processed()`, `path_tables()`, `path_figures()` and `save_plot()`, and creates the output directories.
- For a new exploratory analysis, copy `analysis/main/` to `analysis/<name>/` and replace `analysis/main` (`"analysis", "main"`) with the new directory in `ANALYSIS_DIR` and the header comment of its `00_utils.R`, the paths in its `run_all.R`, and the `source(...00_utils.R)` line at the top of each step.
- Only `.gitkeep` files are tracked under `data/`; raw data stays local and is shared outside git.

# Execution Tips

Lessons worth carrying between projects when running scripts non-interactively (`Rscript`). `00_utils.R` already applies the first two.

- **Unicode in figures**: save plots via `ragg::agg_png()` (`save_plot()` wraps it), not the default `png()` device. The default device garbles characters like `Δ` / `±` depending on the host fonts. `ggsave(..., device = ragg::agg_png)` works too. Japanese / CJK text also needs a CJK font in the image (e.g. `fonts-noto-cjk` via the `apt-packages` feature); without one it is dropped.
- **`Rplots.pdf` / font warnings**: font-metric calculations (`ggplot_build()`, `arrangeGrob()`, …) implicitly open the default `pdf` device and leave a stray `Rplots.pdf` in the working directory. `00_utils.R` calls `grDevices::pdf(NULL)` to absorb it.
- **Composing multi-panel figures**: use `gridExtra::arrangeGrob()` (install `gridExtra` via renv first) and pass the result to `save_plot()`, not `grid.arrange()`. `grid.arrange()` draws to the active device immediately, which triggers the `Rplots.pdf` / garbled-font problems above under `Rscript`.
