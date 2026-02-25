# CLAUDE.md — ambizione-wp2

## Project overview

This repository contains the Stata analysis code for **Work Package 3** of Igor Francetic's Swiss National Science Foundation (SNSF) **Ambizione** fellowship. It contributes directly to the paper:

> **"Disparities in hospital Emergency Department care attributable to language mismatch between patients and hospitals in Switzerland"**

The study estimates disparities in emergency department (ED) resource utilisation caused by language and cultural friction between patients and hospital staff in Switzerland. It uses administrative claims data covering all Swiss outpatient ED visits from 2015 to 2022 (~7.75 million visits).

---

## Research question

Do patients whose language differs from that of the hospital canton receive systematically different care during an ED visit? The analysis focuses on three outcomes:

1. Time spent on basic patient consultation (anamnesis)
2. Time spent on diagnostic activities
3. Number of diagnostic imaging tests ordered

---

## Data sources

| Source | Description | Access |
|--------|-------------|--------|
| **PSA** (Hospital Outpatient Statistics) | Swiss Federal Statistical Office; all outpatient ED visits 2015–2022 | Restricted — requires FSO authorisation |
| **MS** (Hospital Medical Statistics) | Inpatient hospitalisation records; used for Elixhauser comorbidity scoring | Restricted |
| **MedStat education data** | Municipal-level tertiary education attainment, aggregated to MedStat regions (2017 onward) | Derived; stored in `dataout/medstateducation_XXXX.csv` |
| **TARMED tariffs** | Swiss outpatient tariff schedule; provides `flag`, `visit_phase`, and cost weights | `T:\AMBIZIONE\Data\Tariffs\tarmedtariffs.xlsx` |
| **Tariff type list** | Maps `tariftype` codes to descriptions | `T:\AMBIZIONE\Data\PSA\Tariftyp_Liste_20241209.xlsx` |

---

## Sample selection and exclusion criteria

The final analytical sample is built in `prepping.do` after year-specific data preparation. The stages are:

1. **Initial universe**: All records in the PSA outpatient files 2015–2022
2. **Keep ED attendances only**: Records with TARMED codes `35.0610` or `35.05` (`edatt==1`); done in `prepping20XX.do`
3. **Drop anonymous patients**: `is_vcode_aleat == 0` dropped in `prepping20XX.do`
4. **Collapse to visit level**: Services aggregated to one row per `treatment_id × is_vcode_aleat` in `prepping.do`
5. **Exclusion — age**: Drop patients aged ≤15 years (`age_class` ∈ {0, 5, 10}) → `drop if inlist(age_class, 0,5,10)`
6. **Exclusion — referral source**: Drop ambulance/police/justice/missing arrivals (`refsource` ∈ {2, 6, 9}) → `drop if inlist(refsource, 2,6,9)`
7. **Exclusion — no consultation time**: Drop visits where `anamnesistime == 0`
8. **Exclusion — outliers**: Drop visits above the 99th percentile of `anamnesistime`, `diagnosistime`, or `diagimaging`

**Final sample**: ~7.75 million ED visits.

---

## Key variables

### Primary exposure — language-nationality match (`langmatch`)

| Value | Group |
|-------|-------|
| 0 | Swiss citizen, hospital canton matches patient language *(reference)* |
| 1 | Swiss citizen, hospital canton does NOT match patient language |
| 2 | Non-Swiss national, hospital canton language matches patient background |
| 3 | Non-Swiss national, hospital canton language does NOT match |

An extended version (`langmatch_ext`) is used in sensitivity analyses.

### Outcomes

| Variable | Description |
|----------|-------------|
| `time_basic` | Log of anamnesis (consultation) time |
| `any_diagact` | Binary: any diagnostic activity |
| `time_diagact` | Log of diagnostic activity time (conditional on any) |
| `any_diagtest` | Binary: any diagnostic imaging ordered |
| `count_diagtest` | Count of diagnostic imaging tests |
| `service_amount` | Total billed amount (CHF) — used for cost impact analysis |

### Key covariates

| Variable | Description |
|----------|-------------|
| `gender_cd` | Biological sex |
| `age_class` | Age in 5-year bins |
| `finregime` | Financing regime (disability, mandatory, accident, private, etc.) |
| `refsource` | Referral source (self, GP, other provider, hospital internal, other) |
| `elixsum_3y` | Elixhauser comorbidity count (max across same year, 1, 2, and 3 years prior) |
| `visits_prior12` | Count of ED visits in the 12 months prior to the current visit |
| `quintile_tertiary` | Quintile of MedStat-region tertiary education share |
| `medstat` | MedStat region (grouped numeric; used as fixed effect) |
| `month`, `year` | Calendar month and year of visit |

---

## Econometric approach

- **Estimator**: Feasible linear estimator with high-dimensional fixed effects (`reghdfe`; Correia 2016)
- **Fixed effects absorbed**: Year × month × MedStat region (8,472 combinations)
- **Standard errors**: Huber-White heteroscedasticity-robust
- **Main specification**:
  ```stata
  reghdfe outcome b0.langmatch $covariates, a(year month##medstat) vce(robust)
  ```
- **Stratified analysis**: Regressions run separately by `quintile_tertiary` (quintiles of area-level tertiary education)
- **Sensitivity**: Replicated with `langmatch_ext`

---

## Repository structure and workflow

Run scripts in this order:

| Step | Script | Purpose |
|------|--------|---------|
| 1 | `prepping.do` | Master prep — calls year files, merges tariffs, applies exclusions, merges comorbidities and education data |
| *(internal)* | `prepping20XX.do` | Year-specific prep (2015–2022): import PSA files, identify ED visits, flag tariff types |
| *(internal)* | `createlongfile.do` | Reshapes service-level data to long format |
| *(internal)* | `covariates.do` | Constructs derived covariates (nationality groups, canton language codes, log transforms, etc.) |
| *(internal)* | `genoutcomes.do` | Generates outcome variables |
| 2 | `labelling.do` | Applies variable and value labels |
| 3 | `analysis.do` | Runs all regressions, produces tables and figures, cost impact calculations |
| — | `tarmeddes.do` | Utility: imports TARMED procedure code descriptions |

### Global macros expected

The scripts rely on Stata globals set before running (typically in `analysis.do` or a master do-file):

| Global | Points to |
|--------|-----------|
| `$datain` | Root of raw PSA input data (year subfolders) |
| `$dataout` | Working/output data directory |
| `$rawms` | Raw Medical Statistics `.DAT` files |

---

## Branch conventions

Feature branches follow the pattern `claude/<description>-<sessionid>`.
All Claude Code development branches must start with `claude/` and end with the session ID — pushes to branches not matching this pattern will fail with HTTP 403.

---

## Stata notes

- Written for **Stata 19**
- Requires user-written packages: `reghdfe`, `elix22`, `rangestat`
- The `elix22` command implements the Elixhauser (2022 revision) comorbidity index
- `rangestat` is used for the rolling 12-month prior ED visit count
- Install via: `ssc install reghdfe`, `ssc install rangestat`; `elix22` may require manual installation

---

## Data access

Individual patient-level PSA and MS data are restricted. Access requires authorisation from the Swiss Federal Statistical Office. Code is made available following STROBE reporting guidelines; data cannot be shared publicly.

