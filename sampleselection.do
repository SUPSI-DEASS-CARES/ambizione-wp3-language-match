// =========================================================================
// sampleselection.do — ambizione-wp2
// Author : Igor Francetic
// Date   : 25/02/2026
// Purpose: Count visits at each exclusion stage for the patient-flow
//          diagram (fig1.tex) and the attrition table.
//
// Called by: master.do  (Phase 2, after prepping.do)
//
// Requires (produced by prepping.do):
//   $dataout/{year}_long.dta          service-level ED records, 2015-2022
//   $dataout/tarmedtariffs.dta
//   dataout/medstateducation_{year}.dta  (2017-2022)
//   covariates.do and genoutcomes.do in the working directory
//   global $dataout set
//
// Outputs:
//   $dataout/sampleselection.csv          overall attrition table
//   $dataout/sampleselection_byyear.csv   visit counts by year at each stage
//   $dataout/sampleselection_counts.tex   \newcommand values for fig1.tex
// =========================================================================


// =========================================================================
// PART A: ED service lines and unique visits from the long intermediate files
//
// The {year}_long files are service-level and already reflect two early
// filters applied in prepping{year}.do:
//   (i)  edatt == 1  (TARMED codes 35.0610 or 35.05 present in the visit)
//   (ii) is_vcode_aleat != 0  (anonymous patients dropped)
//
// NOTE: counts of ALL PSA outpatient records before the edatt filter are
// not stored in any intermediate file.  To obtain them, uncomment Part A2
// below and ensure the raw HOA_SERVICE_GEO_COMP files are accessible.
// =========================================================================

// --- Part A1: counts from long files (fast) ---

local n_services_total = 0
local n_visits_total   = 0

forvalues x = 2015/2022 {
    use "$dataout/`x'_long", clear

    count
    local n_services_`x' = r(N)
    local n_services_total = `n_services_total' + r(N)

    // Unique visits = distinct (treatment_id x patient) combinations
    duplicates drop treatment_id is_vcode_aleat, force
    count
    local n_visits_`x' = r(N)
    local n_visits_total = `n_visits_total' + r(N)
}

/*
// --- Part A2: optional — count ALL PSA outpatient service lines (slow) ---
//   Uncomment this block to obtain the pre-edatt total.
//   Requires the raw HOA_SERVICE_GEO_COMP files to be accessible.

local n_raw_total = 0
forvalues x = 2015/2022 {
    local n_raw_`x' = 0
    forvalues i = 1/6 {
        capture confirm file "$datain/`x'/HOA_SERVICE_GEO_COMP_`i'_`x'.csv"
        if !_rc {
            import delimited "$datain/`x'/HOA_SERVICE_GEO_COMP_`i'_`x'", clear
            count
            local n_raw_`x' = `n_raw_`x'' + r(N)
        }
    }
    local n_raw_total = `n_raw_total' + `n_raw_`x''
}
*/


// =========================================================================
// PART B: Rebuild the collapsed dataset year by year, then apply each
//         exclusion criterion in sequence.
//
// This mirrors the main collapse loop in prepping.do (lines 38-91) but
// captures counts after each drop rather than applying them all at once.
// =========================================================================

forvalues x = 2015/2022 {
    clear all
    use "$dataout/`x'_long", clear
    merge m:1 service_code using "$dataout/tarmedtariffs"
    drop if _merge == 2
    drop _merge
    do covariates
    do genoutcomes
    gen year = `x'
    collapse (sum) service_amount anamnesistime diagnosistime diagimaging     ///
             (firstnm) *canton month year refsource gender_cd age_class       ///
             medstat_reg_cd nationality grnation finregime,                    ///
             by(treatment_id is_vcode_aleat)
    save "$dataout/sc_`x'", replace
}

clear all
use "$dataout/sc_2022", clear
forvalues x = 2015/2021 {
    append using "$dataout/sc_`x'"
}
sort year treatment_id is_vcode_aleat
forvalues x = 2015/2022 {
    erase "$dataout/sc_`x'.dta"
}

// Merge education data (mirrors prepping.do lines 57-68)
gen medstat_tertshare = .
gen medstat_secshare  = .
gen medstat_compshare = .
forvalues x = 2017/2022 {
    merge m:1 year medstat_reg_cd using "dataout/medstateducation_`x'"
    replace medstat_tertshare = tertiary_share   if missing(medstat_tertshare)
    replace medstat_secshare  = secondary_share  if missing(medstat_secshare)
    replace medstat_compshare = compulsory_share if missing(medstat_compshare)
    drop compulsory_share secondary_share tertiary_share
    drop if _merge == 2
    drop _merge
}
xtile quintile_tertiary = medstat_tertshare, nq(5)
egen medstat = group(medstat_reg_cd)
gen swiss = (nationality == 1)

// --- Baseline: after collapse, before any exclusion ---
count
scalar n0 = r(N)

// --- Year-by-year counts at this baseline stage ---
forvalues x = 2015/2022 {
    count if year == `x'
    scalar n0_`x' = r(N)
}

// --- Exclusion 1: Age ≤15 (age_class in {0, 5, 10}) ---
count if inlist(age_class, 0, 5, 10)
scalar excl_age = r(N)
drop if inlist(age_class, 0, 5, 10)
count
scalar n1 = r(N)
forvalues x = 2015/2022 {
    count if year == `x'
    scalar n1_`x' = r(N)
}

// --- Exclusion 2: Ambulance / police / justice / unknown arrival ---
count if inlist(refsource, 2, 6, 9)
scalar excl_ref = r(N)
drop if inlist(refsource, 2, 6, 9)
count
scalar n2 = r(N)
forvalues x = 2015/2022 {
    count if year == `x'
    scalar n2_`x' = r(N)
}

// --- Exclusion 3: No recorded anamnesis time ---
count if anamnesistime == 0
scalar excl_ana = r(N)
drop if anamnesistime == 0
count
scalar n3 = r(N)
forvalues x = 2015/2022 {
    count if year == `x'
    scalar n3_`x' = r(N)
}

// --- Exclusion 4: Outliers (above 99th percentile) ---
gen temp = .
quietly sum anamnesistime, det
replace temp = 1 if anamnesistime > r(p99)
quietly sum diagnosistime, det
replace temp = 1 if diagnosistime > r(p99)
quietly sum diagimaging, det
replace temp = 1 if diagimaging > r(p99)
count if temp == 1
scalar excl_out = r(N)
drop if temp == 1
drop temp
count
scalar n4 = r(N)
forvalues x = 2015/2022 {
    count if year == `x'
    scalar n4_`x' = r(N)
}


// =========================================================================
// PART C: Compile and export tables
// =========================================================================

// --- Overall attrition table ---

clear
set obs 8

gen str90  stage       = ""
gen double n_remaining = .
gen double n_excluded  = .
gen str20  level       = ""

replace stage       = "All ED service records (PSA, 2015-2022; edatt==1, non-anonymous)" in 1
replace n_remaining = `n_services_total' in 1
replace level       = "Service" in 1

replace stage       = "  deduplicated to unique ED visits (treatment_id x patient_id)" in 2
replace n_remaining = `n_visits_total' in 2
replace n_excluded  = `n_services_total' - `n_visits_total' in 2
replace level       = "Visit" in 2

replace stage       = "After collapsing to visit level and merging tariff/education data" in 3
replace n_remaining = n0 in 3
replace level       = "Visit" in 3

replace stage       = "Exclude: patients aged <=15 years" in 4
replace n_remaining = n1 in 4
replace n_excluded  = excl_age in 4

replace stage       = "Exclude: ambulance, police, justice, or unknown arrival (refsource 2, 6, 9)" in 5
replace n_remaining = n2 in 5
replace n_excluded  = excl_ref in 5

replace stage       = "Exclude: no recorded anamnesis time (anamnesistime == 0)" in 6
replace n_remaining = n3 in 6
replace n_excluded  = excl_ana in 6

replace stage       = "Exclude: outliers (>99th pctile of anamnesistime, diagnosistime, or diagimaging)" in 7
replace n_remaining = n4 in 7
replace n_excluded  = excl_out in 7

replace stage       = "Final analytical sample" in 8
replace n_remaining = n4 in 8

format n_remaining n_excluded %15.0fc

export delimited "$dataout/sampleselection.csv", replace

di _n "=========================================================="
di    "SAMPLE SELECTION — OVERALL"
di    "=========================================================="
list stage n_excluded n_remaining, noobs sep(0) ab(90)
di _n "Final analytical sample: " %15.0fc n4 " ED visits"


// --- By-year breakdown ---

clear
local nrow = 8 * 8   // 8 stages x 8 years
set obs `nrow'

gen str90  stage       = ""
gen int    year        = .
gen double n_remaining = .
gen double n_excluded  = .

local row = 1
foreach yr of numlist 2015/2022 {
    // Stage 1: services
    replace stage       = "ED service records (edatt==1, non-anonymous)" in `row'
    replace year        = `yr' in `row'
    replace n_remaining = `n_services_`yr'' in `row'
    local ++row

    // Stage 2: unique visits
    replace stage       = "Unique ED visits (pre-collapse)" in `row'
    replace year        = `yr' in `row'
    replace n_remaining = `n_visits_`yr'' in `row'
    replace n_excluded  = `n_services_`yr'' - `n_visits_`yr'' in `row'
    local ++row

    // Stage 3: after collapse
    replace stage       = "After collapse" in `row'
    replace year        = `yr' in `row'
    replace n_remaining = n0_`yr' in `row'
    local ++row

    // Stage 4: after age exclusion
    replace stage       = "After excl: age <=15" in `row'
    replace year        = `yr' in `row'
    replace n_remaining = n1_`yr' in `row'
    replace n_excluded  = n0_`yr' - n1_`yr' in `row'
    local ++row

    // Stage 5: after refsource exclusion
    replace stage       = "After excl: refsource 2/6/9" in `row'
    replace year        = `yr' in `row'
    replace n_remaining = n2_`yr' in `row'
    replace n_excluded  = n1_`yr' - n2_`yr' in `row'
    local ++row

    // Stage 6: after zero anatime
    replace stage       = "After excl: anamnesistime == 0" in `row'
    replace year        = `yr' in `row'
    replace n_remaining = n3_`yr' in `row'
    replace n_excluded  = n2_`yr' - n3_`yr' in `row'
    local ++row

    // Stage 7: after outlier exclusion
    replace stage       = "After excl: outliers" in `row'
    replace year        = `yr' in `row'
    replace n_remaining = n4_`yr' in `row'
    replace n_excluded  = n3_`yr' - n4_`yr' in `row'
    local ++row

    // Stage 8: final sample (same as stage 7)
    replace stage       = "Final analytical sample" in `row'
    replace year        = `yr' in `row'
    replace n_remaining = n4_`yr' in `row'
    local ++row
}

format n_remaining n_excluded %15.0fc

export delimited "$dataout/sampleselection_byyear.csv", replace

di _n "=========================================================="
di    "SAMPLE SELECTION — BY YEAR"
di    "=========================================================="
list year stage n_excluded n_remaining, noobs sep(8) ab(50)


// =========================================================================
// PART D: Write LaTeX \newcommand definitions for use in fig1.tex
//
// Produces sampleselection_counts.tex in latex_out.
// Add to the LaTeX preamble:  \input{path/to/sampleselection_counts}
// The figure (fig1.tex) references these commands as \scEdVisits etc.
//
// Change latex_out below to point directly to your LaTeX figures folder,
// or copy the file there after running.
// =========================================================================

local latex_out "$dataout"

// Format counts: comma thousands separator, whitespace trimmed
local cnt_edvisits  = strtrim(string(`n_visits_total',   "%15.0fc"))
local cnt_excl_age  = strtrim(string(scalar(excl_age),   "%15.0fc"))
local cnt_n1        = strtrim(string(scalar(n1),         "%15.0fc"))
local cnt_excl_ref  = strtrim(string(scalar(excl_ref),   "%15.0fc"))
local cnt_n2        = strtrim(string(scalar(n2),         "%15.0fc"))
local cnt_excl_ana  = strtrim(string(scalar(excl_ana),   "%15.0fc"))
local cnt_n3        = strtrim(string(scalar(n3),         "%15.0fc"))
local cnt_excl_out  = strtrim(string(scalar(excl_out),   "%15.0fc"))
local cnt_n4        = strtrim(string(scalar(n4),         "%15.0fc"))

file open fh using "`latex_out'/sampleselection_counts.tex", write replace
file write fh "%% Auto-generated by sampleselection.do -- do not edit manually" _n
file write fh "%% Numbers use comma thousands separators (English convention)." _n
file write fh "%% In math mode use $n = \scFinal$ -- commas render as punctuation." _n
file write fh "" _n
file write fh "\newcommand{\scEdVisits}{`cnt_edvisits'}"  _n
file write fh "\newcommand{\scExclAge}{`cnt_excl_age'}"   _n
file write fh "\newcommand{\scAfterAge}{`cnt_n1'}"        _n
file write fh "\newcommand{\scExclRef}{`cnt_excl_ref'}"   _n
file write fh "\newcommand{\scAfterRef}{`cnt_n2'}"        _n
file write fh "\newcommand{\scExclAna}{`cnt_excl_ana'}"   _n
file write fh "\newcommand{\scAfterAna}{`cnt_n3'}"        _n
file write fh "\newcommand{\scExclOut}{`cnt_excl_out'}"   _n
file write fh "\newcommand{\scFinal}{`cnt_n4'}"           _n
file close fh

di _n "Wrote LaTeX count definitions to: `latex_out'/sampleselection_counts.tex"
