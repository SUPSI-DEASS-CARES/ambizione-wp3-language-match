// =========================================================================
// master.do — ambizione-wp3
// Author : Igor Francetic
// Purpose: Single entry point for the complete analysis pipeline.
//          Run this file; it calls every other do-file in the correct order.
//
// Pipeline
// --------
//   0. Setup       — system directories, global paths, working directory
//   1. prepping    — import raw PSA/MS/tariff data, collapse to visit level,
//                    merge education & comorbidity data, apply exclusions,
//                    label variables, save $dataout/final.dta
//   2. analysis
//                  — count visits at each exclusion stage, export
//                    sampleselection.csv, sampleselection_byyear.csv, and
//                    sampleselection_counts.tex (for fig1.tex)
//   			    — load final.dta, define exposure (langmatch, langmatch_ext),
//                    run regressions, export tables and figures
// =========================================================================


// =========================================================================
// 0. Setup
// =========================================================================

clear all
set more off

// --- System directories (ado-file search paths) ---
sysdir set PLUS     "E:\Users\igor.francetic\ado\plus\"
sysdir set PERSONAL "E:\Users\igor.francetic\ado\personal\"

// --- Global paths ---
global datain  "T:\AMBIZIONE\Data\PSA\raw"       // raw PSA CSV files
global dataout "T:\AMBIZIONE\WP3\Igor\dataout"   // working / output data
global rawms   "T:\AMBIZIONE\Data\MS\raw\"       // raw Medical Statistics .DAT files
global rawdata "T:\AMBIZIONE\Data\"				 // folder with raw data
global main    "T:\AMBIZIONE\WP3\Igor"           // project root (do-files live here)


cd "$main"

di _n "================================================================"
di    " ambizione-wp3 — master pipeline starting"
di    " Working directory: $main"
di    " Data output:       $dataout"
di    "================================================================"


// =========================================================================
// 1. Data preparation
//    Calls internally: prepping20XX.do, createlongfile.do,
//                      covariates.do, genoutcomes.do, labelling.do
//    Produces: $dataout/final.dta   (analytical dataset, ~7.75 m visits)
//              $dataout/{year}_long.dta  (service-level intermediates)
//              $dataout/tarmedtariffs.dta
//              dataout/medstateducation_{year}.dta (2017-2022)
// =========================================================================

di _n "--- Phase 1: Data preparation (prepping.do) ---"
do exe/prepping


// =========================================================================
// 2. Main analysis
//    Reads $dataout/final.dta.
//    Defines exposure variables (langmatch, langmatch_ext).
//    Produces: tables/*.tex, figures/*.eps / *.gph
// =========================================================================

di _n "--- Phase 3: Main analysis (analysis.do) ---"
do analysis


di _n "================================================================"
di    " Pipeline complete."
di    "================================================================"
