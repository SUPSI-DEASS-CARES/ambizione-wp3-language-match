# ambizione-wp2

Research code for Work Package 2 of the Ambizione project. All analysis is written in [Stata](https://www.stata.com/) (`.do` files).

## Repository structure

| File | Purpose |
|---|---|
| `prepping.do` | Main data preparation script |
| `prepping20XX.do` | Year-specific preparation (2015–2022) |
| `createlongfile.do` | Reshapes data to long format |
| `covariates.do` | Constructs covariate variables |
| `labelling.do` | Applies variable and value labels |
| `genoutcomes.do` | Generates outcome variables |
| `analysis.do` | Main analysis script |
| `tarmeddes.do` | TARMED procedure code descriptions |

## Workflow

Run scripts in this order:

1. **Year-specific prep** — `prepping20XX.do` for each relevant year
2. **Main prep** — `prepping.do`
3. **Reshape** — `createlongfile.do`
4. **Covariates & labels** — `covariates.do`, then `labelling.do`
5. **Outcomes** — `genoutcomes.do`
6. **Analysis** — `analysis.do`

## Contributing / syncing a fork

If you have already forked this repository and want to pull in the latest changes:

```bash
# Add upstream once
git remote add upstream https://github.com/igorfrancetic/ambizione-wp2

# Sync your fork
git fetch upstream
git merge upstream/main
git push origin main
```

Alternatively, use the **Sync fork** button on GitHub.

## Branch conventions

Feature branches follow the pattern `claude/<description>-<id>`.
