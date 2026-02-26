# ambizione-wp3

Research code for Work Package 3 of the Ambizione project. All analysis is written in [Stata](https://www.stata.com/) (`.do` files).

## Repository structure

| File | Purpose |
|---|---|
| `analysis.do` | Master and analysis script |
| `prepping.do` | Nested in `analysis.do`: Main data preparation script |
| `prepping20XX.do` | Nested in `prepping.do`: Year-specific preparation (2015–2022) |
| `createlongfile.do` | Nested in `prepping.do`: Reshapes data to long format |
| `covariates.do` | Nested in `prepping.do`: Constructs covariate variables |
| `labelling.do` | Nested in `prepping.do`: Applies variable and value labels |
| `genoutcomes.do` | Nested in `prepping.do`: Generates outcome variables |
| `tarmeddes.do` | Nested in `prepping.do`: TARMED procedure code descriptions |

## Workflow

Run scripts in this order:

0. **Open master do-file** — `analysis.do`, calls `prepping.do'
1. **From the master script, launch prepping script** — `prepping.do` (calls 1.1-1.4 files internally)
   1.1 **Year-specific files** - `prepping20XX.do`
   1.2. **Reshape** — `createlongfile.do`
   1.3. **Covariates & labels** — `covariates.do`, then `labelling.do`
   1.4. **Outcomes** — `genoutcomes.do`
2. **Proceed to analsis from the master script** - scroll down in `analysis.do`
