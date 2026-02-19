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

1. **Main prep** — `prepping.do` (calls the year-specific `prepping20XX.do` files internally)
2. **Reshape** — `createlongfile.do`
3. **Covariates & labels** — `covariates.do`, then `labelling.do`
4. **Outcomes** — `genoutcomes.do`
5. **Analysis** — `analysis.do`

## Branch conventions

Feature branches follow the pattern `claude/<description>-<id>`.
