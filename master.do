// =========================================================================
// master.do — ambizione-wp3
// Author : Igor Francetic
// Purpose: Single entry point for the complete analysis pipeline.
//          Run this file from the project root; it calls every other do-file
//          in the correct order.
//
// Pipeline
// --------
//   0. Setup    — Stata version, paths, folders, required packages
//   1. prepping — exe/prepping.do: import raw PSA/MS/tariff data, collapse to
//                 visit level, merge education & comorbidity data, label
//                 variables, save $dataout/final.dta
//   2. analysis — analysis.do: define exposure (langmatch, langmatch_ext),
//                 run regressions, export tables/ and figures/
// =========================================================================


// =========================================================================
// 0. Setup
// =========================================================================

version 19
clear all
set more off

// --- Global paths (forward slashes work on Windows, Mac and Linux) ---
// Default: the folder you launch Stata from (must be the project root, i.e.
// the folder containing master.do). To override, set $main before running:
//     global main "/path/to/ambizione-wp3-language-match"
if "$main" == "" global main "`c(pwd)'"
capture confirm file "$main/master.do"
if _rc {
    di as error "master.do not found in $main -- cd to the project root or set global main first."
    exit 601
}
global rawdata   "$main/rawdata"                // raw data root
global datain    "$rawdata/PSA"                 // raw PSA CSV files (year subfolders)
global rawms     "$rawdata/MS"                  // raw Medical Statistics .DAT files
global dataout   "$main/dataout"                // working / output data
global shapefile "$rawdata/boundaries/swissBOUNDARIES3D_1_5_TLM_KANTONSGEBIET.shp"  // swisstopo cantons (analysis.do, heatmap only)

cd "$main"
foreach d in dataout tables figures {
    capture mkdir "$main/`d'"
}

// --- Required user-written packages ---
// SSC packages are installed if missing; elix22 must be installed manually.
foreach pkg in ftools reghdfe ppmlhdfe estout coefplot listtex spmap rangestat {
    capture which `pkg'
    if _rc ssc install `pkg', replace
}
capture which elix22
if _rc {
    di as error "elix22 (Elixhauser 2022 comorbidity index) is not installed; install it manually before running."
    exit 111
}

di _n "================================================================"
di    " ambizione-wp3 — master pipeline starting"
di    " Working directory: $main"
di    " Data output:       $dataout"
di    "================================================================"


// =========================================================================
// 1. Data preparation
//    Calls internally: prepping20XX.do, covariates.do, genoutcomes.do,
//                      labelling.do
//    Produces: $dataout/final.dta   (analytical dataset, ~7.75 m visits)
//              $dataout/tarmedtariffs.dta, $dataout/tariftypes.dta
//    Reads:    $dataout/medstateducation_{year}.dta (2017-2022; see AUDIT.md)
// =========================================================================

di _n "--- Phase 1: Data preparation (prepping.do) ---"
do exe/prepping


// =========================================================================
// 2. Main analysis
//    Reads $dataout/final.dta.
//    Defines exposure variables (langmatch, langmatch_ext).
//    Produces: tables/*.tex, figures/*.eps / *.gph
// =========================================================================

di _n "--- Phase 2: Main analysis (analysis.do) ---"
do analysis


di _n "================================================================"
di    " Pipeline complete."
di    "================================================================"
