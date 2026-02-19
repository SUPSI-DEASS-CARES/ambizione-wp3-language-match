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

0. **Open master do-file** — `analysis.do`, calls `prepping.do'
1. **Launch prepping file** — `prepping.do` (calls 1.1-1.4 files internally)
   1.1 **Year-specific files** - `prepping20XX.do`
   1.2. **Reshape** — `createlongfile.do`
   1.3. **Covariates & labels** — `covariates.do`, then `labelling.do`
   1.4. **Outcomes** — `genoutcomes.do`
2. **Proceed to analsis from master** - scroll down in `analysis.do`
