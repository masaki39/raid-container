# Overview

This repository ships with a Rocker-based dev container so you can run R out of the box. You (the agent) run on the **host** and drive R inside the container via `docker exec`.

# Docker Exec Usage

Find the running container name, then issue commands against it.

```zsh
# Find container name
docker ps --filter "label=devcontainer.local_folder=$(pwd)"

# Run an R script
docker exec -i <container-name> Rscript analysis/analysis1/scripts/main.R

# Run a one-liner
docker exec -i <container-name> Rscript -e "cat(R.version\$version.string)"

# Install a package and snapshot
docker exec -i <container-name> Rscript -e "install.packages('pkg'); renv::snapshot()"
```

# Repository Layout

```
analysis/              independent analyses
├─ README.md           overview of each analysis
└─ analysis1/          example analysis directory
   ├─ data/            processed datasets
   ├─ results/         generated outputs
   ├─ scripts/         R scripts
   └─ README.md        details of the analysis
data/                  source datasets
```

# Preinstalled Packages

The dev container ships with the base R distribution and recommended bundles:

- Base packages: `base`, `stats`, `graphics`, `grDevices`, `utils`, `datasets`, `methods`
- Recommended packages: `MASS`, `lattice`, `nlme`, `mgcv`, `survival`, `Matrix`, `boot`, `class`, `cluster`, `codetools`, `foreign`, `KernSmooth`, `nnet`, `rpart`, `spatial`, `splines`, `tcltk`
- Tooling: `parallel`, `tools`, `renv`

Install any additional CRAN/Bioconductor packages as needed and record them via `renv::snapshot()`.

# Analysis Guidelines

- Write analyses as `.R` scripts rather than R Markdown.
- Exclude binary artifacts via `.gitignore`; rely on scripts for reproducibility.
- Prefer the R packages baked into the Docker image; install extras only when needed.
- Capture newly installed packages with `renv`.
- When an analysis milestone is reached, create a git commit to save the state.
