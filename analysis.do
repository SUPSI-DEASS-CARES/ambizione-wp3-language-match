// Author: Igor Francetic
// Date: 19/02/2026
// Main analysis do-file

clear all

// Set system directory paths
sysdir set PLUS  "E:\Users\igor.francetic\ado\plus\" 
sysdir set PERSONAL "E:\Users\igor.francetic\ado\personal\" 

// Set globals
global datain T:\AMBIZIONE\Data\PSA\raw
global dataout T:\AMBIZIONE\WP3\Igor\dataout
global main T:\AMBIZIONE\WP3\Igor
global rawms T:\AMBIZIONE\Data\MS\raw\
cd "$main"

// Launch flow for preparing data (fairly long to execute, starts from raw data)
do prepping

// Open the prepped data ready to be analysed
clear all
use "$dataout/final", clear

// Explore differences across nationality groups for specific indicators of time spent with patient

// Define matches between nationality and language of the ED canton
gen canton_language=.
replace canton_language=1 if inlist(hosp_canton,"AG","AI","AR","BE","BL","BS","FR","GL","GR") // German speaking
replace canton_language=1 if inlist(hosp_canton,"LU","NW","OW","SG","SH","SO","SZ","TG","UR") // German speaking
replace canton_language=1 if inlist(hosp_canton,"VS","ZG","ZH") // German speaking
replace canton_language=2 if inlist(hosp_canton, "BE","FR","GE","JU","NE","VD","VS") // French speaking
replace canton_language=3 if inlist(hosp_canton,"TI") // Italian speaking

// Define language in patient's canton of residence
gen patientcan_language=.
replace patientcan_language=1 if inlist(pat_canton,"AG","AI","AR","BE","BL","BS","FR","GL","GR") // German speaking
replace patientcan_language=1 if inlist(pat_canton,"LU","NW","OW","SG","SH","SO","SZ","TG","UR") // German speaking
replace patientcan_language=1 if inlist(pat_canton,"VS","ZG","ZH") // German speaking
replace patientcan_language=2 if inlist(pat_canton, "BE","FR","GE","JU","NE","VD","VS") // French speaking
replace patientcan_language=3 if inlist(pat_canton,"TI") // Italian speaking

// Define patient language categories
gen patient_language=.
replace patient_language=0 if pat_canton==hosp_canton&swiss==1
replace patient_language=0 if (pat_canton!=hosp_canton)&swiss==1&(canton_language==patientcan_language)
replace patient_language=1 if inlist(grnation,2,5)
replace patient_language=2 if grnation==3
replace patient_language=3 if grnation==4
replace patient_language=9 if grnation>4&grnation!=.
replace patient_language=99 if pat_canton!=hosp_canton&grnation==1&canton_language!=patientcan_language

// Define classification of Swiss vs. matching non-Swiss vs. non-matching non-Swiss (leave out non-matching Swiss)
gen langmatch=0 if patient_language==0 // Swiss in canton with matching language
replace langmatch=2 if patient_language==patientcan_language&swiss==0 // Non-Swiss in language-matching canton
replace langmatch=3 if patient_language!=patientcan_language&swiss==0 // Non-Swiss in canton with non-matching language
replace langmatch=3 if patient_language==9 // Non-Swiss in canton with non-matching language
replace langmatch=1 if patient_language==99 // Swiss in non-matching language canton
label define langlab 0 "Swiss, matching language" 1 "Swiss, non-matching language" 2 "Non-Swiss, matching language" 3 "Non-Swiss, non-matching language"
label values langmatch langlab

// Extended classification: Africa and East Europe as a separate category
gen langmatch_ext=langmatch
replace langmatch_ext=4 if inlist(grnation, 7, 9, 10, 11) // East Europe and Africa (any language match)
label define langlab_ext 0 "Swiss, matching language" 1 "Swiss, non-matching language" 2 "Non-Swiss, matching language" 3 "Non-Swiss, non-matching language" 4 "Africa and East Europe"
label values langmatch_ext langlab_ext

// Set globals
global covariates i.gender_cd##i.age_class b2.finregime i.refsource b0.visits_prior12
global outcomes time_basic any_diagact time_diagact any_diagtest count_diagtest

// Descriptives
gen grouping=langmatch
label define grlab 0 "Swiss, matching" 1 "Swiss, non-matching" 2 "Non-Swiss, matching" 3 "Non-Swiss, non-matching"
label values grouping grlab
dtable $outcomes i.gender i.age_class i.finregime i.refsource visits_prior12 i.quintile_tertiary i.year, by(grouping) export("tables/table1.tex", replace tableonly)
hist time_basic, saving(figures/out1, replace) percent
hist time_diagact, saving(figures/out2, replace) percent
hist count_diagtest, saving(figures/out3, replace) percent
graph combine figures/out1.gph figures/out2.gph figures/out3.gph, row(1)
graph export figures/fig2.eps, replace

// Analyses

// Unadjusted regressions
eststo clear
foreach var of global outcomes {
eststo: reghdfe `var' b0.langmatch, a(year month##medstat) vce(robust)
qui: sum `var' if e(sample)==1&langmatch==0
scalar avgy = `r(mean)' 
estadd scalar avgy=`=avgy'
estadd local controls "No"
estadd local season "Yes"
est save tables/unadj_`var', replace
}
esttab, keep(*langmatch*) label replace scalars(N avgy) mtitles("(Log) Base time" "Any diag. time" "(Log) diag time" "Any diag. imag. test" "Count of diag. imag. tests")
esttab using "tables\tabularsm2_unadj.tex", keep(*langmatch*) label replace mtitles("Base time" "Any diag. time" "(Log) diag time" "Any diag. imag. test" "Count of diag. imag. tests") scalars("controls Covariates" "season MedStat x Month seasonality" "N Observations" "avgy Outcome average for ref. group") nobase ci nonotes

// Regressions including covariates
eststo clear
foreach var of global outcomes {
eststo: reghdfe `var' b0.langmatch $covariates, a(year month##medstat) vce(robust)
qui: sum `var' if e(sample)==1&langmatch==0
scalar avgy = `r(mean)' 
estadd scalar avgy=`=avgy'
est save tables/adj_`var', replace
}

// Export tables
esttab *, keep(*langmatch*) label replace scalars(N avgy) mtitles("(Log) Base time" "Any diag. time" "(Log) diag time" "Any diag. imag. test" "Count of diag. imag. tests") 
esttab * using "tables\tabular2_adj.tex", keep(*langmatch*) label replace scalars("controls Covariates" "season MedStat x Month seasonality" "N Observations" "avgy Outcome average for ref. group") mtitles("(Log) Base time" "Any diag. time" "(Log) diag time" "Any diag. imag. test" "Count of diag. imag. tests") nobase ci nonotes
esttab * using "tables\tabularsm3_full.tex", label replace scalars("controls Covariates" "season MedStat x Month seasonality" "N Observations" "avgy Outcome average for ref. group") mtitles("(Log) Base time" "Any diag. time" "(Log) diag time" "Any diag. imag. test" "Count of diag. imag. tests") nobase 
// Export main coefficient plot
coefplot (est1, label("(Log) Base time") msymbol(+)) (est2, label("Any diag. time") msymbol(S)) (est3, label("(Log) diag. time")) ///
(est4, label("Any diag. imag. test") msymbol(D)) (est5, label("Count of diag. imag. tests") msymbol(T)), keep(*langmatch*) xline(0, lcol(red)) saving(figures/fig3, replace)
graph export figures/fig3.eps, replace

// Regressions including covariates and interaction with MedStat education quintile
eststo clear
foreach var of global outcomes {
reghdfe `var' b0.langmatch##b5.quintile_tertiary $covariates, a(year month##medstat) vce(robust)
est save tables/qedu_`var', replace
qui: sum `var' if e(sample)==1&langmatch==0
scalar avgy = `r(mean)' 
eststo: margins r.langmatch, post over(quintile_tertiary)
estadd scalar avgy=`=avgy'
estadd local controls "Yes"
estadd local season "Yes"
marginsplot, saving(figures/quant_`var', replace)
}

// Export tables
esttab, keep(*langmatch*) lab scalars(N avgy)
esttab, keep(*langmatch*) label replace scalars(N avgy) mtitles("(Log) Base time" "Any diag. time" "(Log) diag time" "Any diag. imag. test" "Count of diag. imag. tests") nobase ci nonotes
esttab using "tables\tabular3.tex", keep(*langmatch*) label replace mtitles("(Log) Base time" "Any diag. time" "(Log) diag time" "Any diag. imag. test" "Count of diag. imag. tests") nobase ci nonotes scalars("controls Covariates" "season MedStat x Month seasonality" "N Observations" "avgy Outcome average for ref. group")

////////////////////////////////////////////////////
// ---- Cost impact analysis ----
////////////////////////////////////////////////////

// Step 1: Estimate adjusted per-patient cost difference (CHF)
reghdfe costs b0.langmatch $covariates, a(year month##medstat) vce(robust)

// Step 2: Retrieve coefficients for each contrast group
forvalues cat = 1/3 {
    scalar delta_`cat' = _b[`cat'.langmatch]
}

// Step 3: Scale up to population level by year
preserve
    keep if e(sample)
    collapse (count) n = costs (sum) totalspend=service_amount, by(langmatch year)

    gen cost_impact = 0
    forvalues cat = 1/3 {
        replace cost_impact = delta_`cat' * n if langmatch == `cat'
    }

    // Aggregate excess billing (CHF) across groups within each year
    collapse (sum) total_cost_impact_chf = cost_impact (sum) totalspend (sum) n_total = n, by(year)
	gen perc_impact=round(total_cost_impact_chf/totalspend*100, 0.01)
    list year n_total total_cost_impact_chf totalspend perc_impact
	mkmat _all, matrix(D)
	esttab matrix(D) using "tables\cost_impact.tex", replace
restore

// ---- Sensitivity analysis: langmatch_ext as exposure ----
// Replicates the main analysis using the extended classification that separates
// Africa and East Europe from the broader non-matching non-Swiss group.

// Regressions including covariates
eststo clear
foreach var of global outcomes {
eststo: reghdfe `var' b0.langmatch_ext $covariates, a(year month##medstat) vce(robust)
qui: sum `var' if e(sample)==1&langmatch_ext==0
scalar avgy = `r(mean)'
estadd scalar avgy=`=avgy'
est save tables/sa_adj_`var', replace
}

// Export tables
esttab *, keep(*langmatch_ext*) label replace scalars(N avgy) mtitles("(Log) Base time" "Any diag. time" "(Log) diag time" "Any diag. imag. test" "Count of diag. imag. tests")
esttab * using "tables\sa_tabular2_adj.tex", keep(*langmatch_ext*) label replace scalars("controls Covariates" "season MedStat x Month seasonality" "N Observations" "avgy Outcome average for ref. group") mtitles("(Log) Base time" "Any diag. time" "(Log) diag time" "Any diag. imag. test" "Count of diag. imag. tests") nobase ci nonotes
esttab * using "tables\sa_tabularsm3_full.tex", label replace scalars("controls Covariates" "season MedStat x Month seasonality" "N Observations" "avgy Outcome average for ref. group") mtitles("(Log) Base time" "Any diag. time" "(Log) diag time" "Any diag. imag. test" "Count of diag. imag. tests") nobase
// Export coefficient plot
coefplot (est1, label("(Log) Base time") msymbol(+)) (est2, label("Any diag. time") msymbol(S)) (est3, label("(Log) diag. time")) ///
(est4, label("Any diag. imag. test") msymbol(D)) (est5, label("Count of diag. imag. tests") msymbol(T)), keep(*langmatch_ext*) xline(0, lcol(red)) saving(figures/sa_fig3, replace)
graph export figures/sa_fig3.eps, replace

// Regressions including covariates and interaction with MedStat education quintile
eststo clear
foreach var of global outcomes {
reghdfe `var' b0.langmatch_ext##b5.quintile_tertiary $covariates, a(year month##medstat) vce(robust)
est save tables/sa_qedu_`var', replace
qui: sum `var' if e(sample)==1&langmatch_ext==0
scalar avgy = `r(mean)'
eststo: margins r.langmatch_ext, post over(quintile_tertiary)
estadd scalar avgy=`=avgy'
estadd local controls "Yes"
estadd local season "Yes"
marginsplot, saving(figures/sa_quant_`var', replace)
}

// Export tables
esttab *, keep(*langmatch_ext*) lab scalars(N avgy)
esttab *, keep(*langmatch_ext*) label replace scalars(N avgy) mtitles("(Log) Base time" "Any diag. time" "(Log) diag time" "Any diag. imag. test" "Count of diag. imag. tests") nobase ci nonotes

esttab using "tables\sa_tabular3.tex", keep(*langmatch_ext*) label replace mtitles("(Log) Base time" "Any diag. time" "(Log) diag time" "Any diag. imag. test" "Count of diag. imag. tests") nobase ci nonotes scalars("controls Covariates" "season MedStat x Month seasonality" "N Observations" "avgy Outcome average for ref. group")
