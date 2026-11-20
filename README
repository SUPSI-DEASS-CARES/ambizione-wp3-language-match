# ambizione-wp3

Stata analysis code for **Work Package 3** of Igor Francetic's Swiss National Science Foundation (SNSF) Ambizione fellowship.

> **"Disparities in hospital Emergency Department care attributable to language mismatch between patients and hospitals in Switzerland"**

The study estimates disparities in emergency department (ED) resource utilisation caused by language and cultural friction between patients and hospital staff, using administrative claims data covering all Swiss outpatient ED visits from 2015 to 2022 (~7.75 million visits).

---

## Requirements

- **Stata 19**
- User-written packages: `ftools`, `reghdfe`, `ppmlhdfe`, `estout`, `coefplot`, `listtex`, `spmap`, `rangestat` (installed automatically from SSC by `master.do`) and `elix22` (Elixhauser 2022 comorbidity index; must be installed manually, `master.do` stops if it is missing).

---

## Data access

Individual patient-level data (PSA, Medical Statistics) are restricted. Access requires authorisation from the Swiss Federal Statistical Office. Code is made available following STROBE reporting guidelines; data cannot be shared publicly.

---

## Workflow

**Run a single file:**

```stata
do master
```

`master.do` sets all paths and globals (defaulting `$main` to the folder Stata is launched from), creates `dataout/`, `tables/` and `figures/`, checks required packages, then calls the two phases in order:

| Phase | Script | What it does |
|-------|--------|-------------|
| 1 | `exe/prepping.do` | Imports raw PSA/MS/tariff data, collapses to visit level, merges education and comorbidity data, applies exclusions, saves `$dataout/final.dta` |
| 2 | `analysis.do` | Loads `final.dta`, defines exposure variables, runs regressions, exports tables and figures |

`analysis.do` can also be run standalone (after `exe/prepping.do`) once the setup block of `master.do` has defined the globals.

---

## Repository structure

### Entry point

| File | Purpose |
|------|---------|
| `master.do` | **Run this.** Sets paths/globals and calls all phases in order. |

### Data preparation (Phase 1)

| File | Purpose |
|------|---------|
| `exe/prepping.do` | Master prep — calls year files, merges tariffs, applies exclusions, merges comorbidities and education data |
| `prepping20XX.do` | Year-specific prep (2015–2022): imports PSA files, identifies ED visits, flags tariff types |
| `covariates.do` | **Called by `prepping.do` but not currently in the repository** — see `AUDIT.md` |
| `genoutcomes.do` | Generates outcome variables |
| `labelling.do` | Applies variable and value labels |

### Analysis (Phase 2)

| File | Purpose |
|------|---------|
| `analysis.do` | Defines `langmatch`/`langmatch_ext`, runs all regressions (main + sensitivity), exports tables and figures |

---

## Global macros

Set in `master.do` (edit these to match your environment):

| Global | Description |
|--------|-------------|
| `$datain` | Root of raw PSA input data (year subfolders) |
| `$dataout` | Working/output data directory |
| `$rawms` | Raw Medical Statistics `.DAT` files |
| `$main` | Project root; defaults to the launch directory, which must contain `master.do` |
| `$rawdata` | `rawdata/` folder |
| `$shapefile` | swisstopo canton shapefile for the heatmap (not in repo) |

---
