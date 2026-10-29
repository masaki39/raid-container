# main

The production pipeline. Run it from the repo root:

```zsh
bin/r analysis/main/scripts/run_all.R
```

## Intent

<!-- The question this analysis answers and why. -->

## Inputs

<!-- Files under data/raw/ (source, version or date received) and any data/processed/ files this pipeline reads. -->

## Steps

| Script | What it does |
|---|---|
| `00_utils.R` | Shared helpers: repo-root check, path helpers, `save_plot()` |
| `run_all.R` | Sources `00_utils.R` and every numbered step in order |

## Outputs

- `results/tables/` — generated `.csv` (tracked in git)
- `results/figures/` — generated images (not tracked; regenerate with `run_all.R`)

## Results

<!-- Key findings, with pointers to the tables / figures that support them. -->
