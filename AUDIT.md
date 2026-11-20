# Replicability audit

Static review only. Stata and the restricted data were not available, so nothing was executed. Items under "Open" need action from the project team.

## Fixed in this branch

| File | Problem | Fix |
|------|---------|-----|
| `master.do` | `$main` was the placeholder `YOURPATH`; Windows `\` separators and trailing slashes in globals | Defaults to the launch directory with a check for `master.do`; forward slashes; no trailing slashes |
| `master.do` | No `version`; `tables/`, `figures/`, `dataout/` not created (every `esttab`, `graph export` and `save` would fail on a clean checkout) | Added `version 19` and `mkdir` |
| `master.do` | Only `reghdfe`, `rangestat`, `elix22` were documented; the code also needs `ftools`, `ppmlhdfe`, `estout`, `coefplot`, `listtex`, `spmap` | Package check and SSC install; hard stop if `elix22` is missing |
| `master.do` / README | Described `sampleselection.do`, `createlongfile.do`, `tarmeddes.do`, `fig1.tex`, which are not in the repo and not called by any code; phase numbering inconsistent | Removed stale references; phases renumbered |
| `exe/prepping.do`, `exe/prepping20XX.do` | Mixed `\` and `/` separators, and relative `dataout/` paths that bypassed `$dataout` | All paths use `$dataout`, `$rawms`, `$datain`, `$rawdata` with `/` and quotes |
| `exe/prepping20XX.do` (all 8) | `inlist(tariftype, ..., 337 907, ...)` is missing a comma, which is a syntax error | Added the comma |
| `analysis.do` | `i.gender` in the table 1 `dtable` call relied on variable abbreviation | `i.gender_cd` |
| `analysis.do` | Unadjusted tables stored the model as `model` but exported `estm`, so that row was blank | `estm` |
| `analysis.do` | Cost regressions with covariates were labelled `controls "No"` (adjusted and sensitivity tables) | `"Yes"` |
| `analysis.do` | Age-80+ table had a stray `"estm Model"` column title that shifted the others | Removed |
| `analysis.do` | `log using` failed on re-run if a log was open; shapefile path hard-coded to `T:/AMBIZIONE/...` and `shp2dta` rerun each time | `capture log close`; `$shapefile` global; conversion skipped if output exists |

## Open — needed to replicate

1. **`exe/covariates.do` is missing.** `prepping.do` calls it. It must create `hosp_canton`, `pat_canton`, `grnation`, and the other variables `analysis.do` uses (`age_class`, `nationality` and so on). Without it the pipeline stops at `prepping.do`.
2. **`dataout/medstateducation_{2017..2022}.dta` has no code that builds it.** `prepping.do` merges these files in. Add the script and its raw source (probably BFS education data), or document where they come from.
3. **No data dictionary or documented raw-data layout.** `rawdata/PSA/<year>/HOA_TREATMENT_GEO_COMP_<year>.csv`, `HOA_SERVICE_GEO_COMP_1..6_<year>` and `rawdata/MS/DATA_BFS_MS_240521_<year>.DAT` (2013–2022) are expected. Say which BFS delivery these come from.
4. **The swisstopo shapefile is not in the repo.** It is needed only for `canton_heatmap.eps`. Add the source and version of `swissBOUNDARIES3D_1_5_TLM_KANTONSGEBIET`.
5. **`elix22` has no known install source.** Document the URL or bundle it.

## Open — risks to review

- **`finregime=group(law_content_cd)`** runs inside each year file before the years are appended. Group numbers are assigned by sort order within each year, so they can mean different regimes in different years if the set of values differs. It is used as a covariate with base category 2. Build it after appending, or from the raw codes.
- **Year-specific tariff-code lists.** The only difference between the eight `prepping20XX.do` files is the extra codes mapped to `"999"` (`GTI`, `PH2` in 2017; `T33` in 2019, 2021 and 2022). I left them as separate files, because merging them could change results if a code appears in another year's data. Consider one parameterised file.
- **Overlapping `serv_*` dummies** (for example 910 in both inpatient and protection/support; 551 and 552 in outpatient and maternity). They do not appear to be used downstream, but they should not be reported as exclusive categories.
- **`collapse (firstnm)`** takes the first non-missing value in the existing sort order, which depends on the order the raw files arrive in. Add an explicit sort on `treatment_id` and a service identifier if patient covariates can vary within a visit.
- **p99 outlier cut-offs and the `visits_prior12` cap** are computed on the full pooled data (2015–2022, before the sample restrictions). This is reproducible, but it is a design choice that should be stated in the methods.
- **`_4_2_v270` is kept on import but never renamed or used.** This is harmless.
- **No `set varabbrev off`.** I fixed the one abbreviation I found, so enabling it would catch any others.
