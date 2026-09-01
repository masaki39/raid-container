# Overview

This repository ships with a Rocker-based dev container so you can run R out of the box. You (the agent) run on the **host** and drive R inside the container via `docker exec`.

# Container Startup

If VS Code is not driving the container (e.g. host is macOS + Colima), bring it up yourself:

```zsh
# 1. Start the Docker daemon (skip if already running)
colima start

# 2. Bring up the dev container (run from the repo root)
devcontainer up --workspace-folder .
#   → note the containerId in the output
#   `pnpm dlx @devcontainers/cli up --workspace-folder .` also works if the CLI is not installed

# 3. First run only: restore renv packages
#    On Apple Silicon the linux/amd64 image runs under QEMU, so this can take a while.
docker exec -w /workspaces/<repo-name> <containerId> \
  Rscript -e 'renv::restore(prompt = FALSE)'
```

- An already-running container can be reused (`docker ps`); restart a stopped one with `docker start <containerId>`.
- The renv cache is persisted in a Docker volume, so later `renv::restore()` runs are fast.

# Docker Exec Usage

Find the running container name, then issue commands against it.

```zsh
# Find container name
docker ps --filter "label=devcontainer.local_folder=$(pwd)"

# Run an R script (always pass -w so the working directory is the repo root)
docker exec -w /workspaces/<repo-name> <container-name> Rscript analysis/main/scripts/run_all.R

# Run a one-liner
docker exec -w /workspaces/<repo-name> <container-name> Rscript -e "cat(R.version\$version.string)"

# Install a package and snapshot
docker exec -w /workspaces/<repo-name> <container-name> Rscript -e "install.packages('pkg'); renv::snapshot()"
```

# Execution Rules

- **Always run R from the repo root** (`/workspaces/<repo-name>`). `renv` is managed at the root, so `cd`-ing into a sub-directory breaks package resolution. Use `docker exec -w <root>` rather than `cd`, and write script paths relative to the root (`analysis/main/scripts/01_foo.R`).
- Write analyses as `.R` scripts rather than R Markdown.
- Exclude binary artifacts via `.gitignore`; rely on scripts for reproducibility.
- Prefer the R packages baked into the Docker image; install extras only when needed, and capture them with `renv::snapshot()`.
- When an analysis milestone is reached, create a git commit to save the state.

# Repository Layout

```
analysis/              independent analyses
├─ main/               the production pipeline (final deliverable)
│  ├─ scripts/         00_utils.R + numbered steps (01_, 02_, …) + run_all.R
│  ├─ results/
│  │  ├─ tables/       generated .csv
│  │  └─ figures/      generated images
│  └─ README.md        intent, steps, and results
└─ <name>/             exploratory / one-off analyses, same internal shape
data/
├─ raw/                source datasets (immutable)
└─ processed/          derived datasets (reproducible from scripts; git-ignored)
```

- `analysis/main/` holds the settled pipeline. Promote code here once it is confirmed in an exploratory directory.
- Give each analysis directory its own `README.md` and number the scripts so the run order is explicit. A `run_all.R` that `source()`s the steps in order makes the whole pipeline one command.

# Preinstalled Packages

The dev container ships with the base R distribution and recommended bundles:

- Base packages: `base`, `stats`, `graphics`, `grDevices`, `utils`, `datasets`, `methods`
- Recommended packages: `MASS`, `lattice`, `nlme`, `mgcv`, `survival`, `Matrix`, `boot`, `class`, `cluster`, `codetools`, `foreign`, `KernSmooth`, `nnet`, `rpart`, `spatial`, `splines`, `tcltk`
- Tooling: `parallel`, `tools`, `renv`

Install any additional CRAN/Bioconductor packages as needed and record them via `renv::snapshot()`.

# Execution Tips

Lessons worth carrying between projects when running scripts non-interactively (`Rscript`):

- **Unicode in figures**: save plots via `ragg::agg_png()` (or a wrapper around it), not the default `png()` device. The default device garbles characters like `Δ` / `±` depending on the host fonts. `ggsave(..., device = ragg::agg_png)` works too.
- **`Rplots.pdf` / font warnings**: font-metric calculations (`ggplot_build()`, `arrangeGrob()`, …) implicitly open the default `pdf` device and leave a stray `Rplots.pdf` in the working directory. Put `grDevices::pdf(NULL)` near the top of shared utilities to absorb it.
- **Composing multi-panel figures**: use `gridExtra::arrangeGrob()`, not `grid.arrange()`. `grid.arrange()` draws to the active device immediately, which triggers the `Rplots.pdf` / garbled-font problems above under `Rscript`.
- **Paths**: build them with `file.path()` from the repo root; never assume the process CWD is the script's directory.
