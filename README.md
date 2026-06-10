# RAID Container (R × AI × Dev Container)

Reproducible R analysis workspace powered by Dev Containers. An AI agent running on the host drives the container via `docker exec`.

## What You Need

1. **Dev Containers** — VS Code + Dev Containers extension, or the [`devcontainer` CLI](https://github.com/devcontainers/cli)
2. **A container runtime** — Docker Desktop, Colima, etc.
3. **Git**
4. An AI agent on the host — Claude Code, Codex CLI, etc.

## Launch

1. **Clone and open** the repo.
   ```zsh
   git clone https://github.com/masaki39/raid-container
   code raid-container
   ```
2. **Reopen in Container** when VS Code prompts you; wait for the Rocker image to boot.
   - If the prompt does not appear, run `Dev Containers: Rebuild Container` manually.

## Agent Workflow

The agent runs **on the host** and communicates with the container via `docker exec`.

```zsh
# Find the running container name
docker ps

# Run an R script inside the container
docker exec -i <container-name> Rscript analysis/analysis1/scripts/main.R

# Run a one-liner
docker exec -i <container-name> Rscript -e "sessionInfo()"
```

Drop your data in `data/`, open your agent, and hand off the analysis request.

## System Dependencies

To install additional system packages, add them to `.devcontainer/devcontainer.json`:

```json
"features": {
    "ghcr.io/rocker-org/devcontainer-features/apt-packages:1": {
        "packages": [
            "r-cran-kableextra",
            "libxml2-dev"
        ]
    }
},
```
