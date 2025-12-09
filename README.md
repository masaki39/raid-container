# RAID Container (R × AI × Dev Container)

AI-first R analysis workspace powered by Dev Containers. Hand off your analysis to an AI agent while keeping the environment reproducible.

## What You Need

1. [**VS Code**](https://code.visualstudio.com/) with the Dev Containers extension.
2. [**Docker Desktop**](https://www.docker.com/products/docker-desktop/)
3. [**Git**](https://git-scm.com/downloads)
4. (Optional) [**Codex CLI**](https://developers.openai.com/codex/cli) or [**Claude Code**](https://claude.com/product/claude-code)—pick your favorite co-pilot.

## Launch & Let Agents Work

1. **Clone and open** the repo.
   ```zsh
   git clone https://github.com/masaki39/raid-container
   code raid-container
   ```
2. **Reopen in Container** when VS Code prompts you; wait for the Rocker image to boot.  
   - If the prompt does not appear, run `Dev Containers: Rebuild Container` manually.
3. **Launch your agent** inside the container (`codex`, `claude`, etc.).
4. **Drop your data in place, hand the request to the agent, and let it drive the workflow end-to-end.**
