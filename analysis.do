// Author: Igor Francetic
// Date: 19/02/2026
// Main analysis do-file

clear all

// Set system directory paths
sysdir set PLUS  "E:\Users\igor.francetic\ado\plus\" 
sysdir set PERSONAL "E:\Users\igor.francetic\ado\personal\" 

// Set globals
global datain T:\AMBIZIONE\Data\PSA\raw
global dataout T:\AMBIZIONE\WP2\Igor\dataout
global main T:\AMBIZIONE\WP2\Igor
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

// Define broad age groups for stratified analysis
// Groups align with 5-year age_class bins (lower-bound convention):
//   1 = 15–39  (age_class 15, 20, 25, 30, 35)
//   2 = 40–69  (age_class 40, 45, 50, 55, 60, 65)
//   3 = 70–79  (age_class 70, 75)
//   4 = 80+    (age_class 80, 85)
gen agegroup = 1 if inlist(age_class, 15, 20, 25, 30, 35)
replace agegroup = 2 if inlist(age_class, 40, 45, 50, 55, 60, 65)
replace agegroup = 3 if inlist(age_class, 70, 75)
replace agegroup = 4 if inlist(age_class, 80, 85)
label define agegrouplab 1 "15–39" 2 "40–69" 3 "70–79" 4 "80+"
label values agegroup agegrouplab

// Set globals
global covariates i.gender_cd##i.age_class b2.finregime i.refsource b0.visits_prior12
global outcomes time_basic any_diagact time_diagact any_diagtest count_diagtest

// Descriptives
gen grouping=langmatch
label define grlab 0 "Swiss" 1 "Contrast 1" 2 "Contrast 2" 3 "Contrast 3"
label values grouping grlab
dtable $outcomes i.gender i.age_class i.finregime i.refsource elixsum_3y i.quintile_tertiary i.year, by(grouping) export("tables/table1.tex", replace tableonly)
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

// Split-sample regressions stratified by broad age group
// One table and one coefficient plot per age group (g=1: 15–39, 2: 40–69, 3: 70–79, 4: 80+)
forvalues g = 1/4 {
    eststo clear
    foreach var of global outcomes {
        eststo: reghdfe `var' b0.langmatch $covariates if agegroup == `g', a(year month##medstat) vce(robust)
        qui: sum `var' if e(sample)==1 & langmatch==0
        scalar avgy = `r(mean)'
        estadd scalar avgy=`=avgy'
        estadd local controls "Yes"
        estadd local season "Yes"
        est save tables/age`g'_`var', replace
    }
    esttab * using "tables/tabular_age`g'.tex", keep(*langmatch*) label replace ///
        mtitles("(Log) Base time" "Any diag. time" "(Log) diag time" "Any diag. imag. test" "Count of diag. imag. tests") ///
        scalars("controls Covariates" "season MedStat x Month FE" "N Observations" "avgy Ref. group mean") ///
        nobase ci nonotes
    coefplot (est1, label("(Log) Base time") msymbol(+)) (est2, label("Any diag. time") msymbol(S)) ///
             (est3, label("(Log) diag. time")) (est4, label("Any diag. imag. test") msymbol(D)) ///
             (est5, label("Count of diag. imag. tests") msymbol(T)), ///
        keep(*langmatch*) xline(0, lcol(red)) saving(figures/age`g'_coef, replace)
    graph export figures/age`g'_coef.eps, replace
}

// ---- Sensitivity analysis: langmatch_ext as exposure ----
// Replicates the main analysis using the extended classification that separates
// Africa and East Europe from the broader non-matching non-Swiss group.

// Unadjusted regressions
eststo clear
foreach var of global outcomes {
eststo: reghdfe `var' b0.langmatch_ext, a(year month##medstat) vce(robust)
qui: sum `var' if e(sample)==1&langmatch_ext==0
scalar avgy = `r(mean)'
estadd scalar avgy=`=avgy'
estadd local controls "No"
estadd local season "Yes"
est save tables/sa_unadj_`var', replace
}
esttab, keep(*langmatch_ext*) label replace scalars(N avgy) mtitles("(Log) Base time" "Any diag. time" "(Log) diag time" "Any diag. imag. test" "Count of diag. imag. tests")
esttab using "tables\sa_tabularsm2_unadj.tex", keep(*langmatch_ext*) label replace mtitles("Base time" "Any diag. time" "(Log) diag time" "Any diag. imag. test" "Count of diag. imag. tests") scalars("controls Covariates" "season MedStat x Month seasonality" "N Observations" "avgy Outcome average for ref. group") nobase ci nonotes

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

// Split-sample regressions stratified by broad age group (sensitivity: langmatch_ext)
forvalues g = 1/4 {
    eststo clear
    foreach var of global outcomes {
        eststo: reghdfe `var' b0.langmatch_ext $covariates if agegroup == `g', a(year month##medstat) vce(robust)
        qui: sum `var' if e(sample)==1 & langmatch_ext==0
        scalar avgy = `r(mean)'
        estadd scalar avgy=`=avgy'
        estadd local controls "Yes"
        estadd local season "Yes"
        est save tables/sa_age`g'_`var', replace
    }
    esttab * using "tables/sa_tabular_age`g'.tex", keep(*langmatch_ext*) label replace ///
        mtitles("(Log) Base time" "Any diag. time" "(Log) diag time" "Any diag. imag. test" "Count of diag. imag. tests") ///
        scalars("controls Covariates" "season MedStat x Month FE" "N Observations" "avgy Ref. group mean") ///
        nobase ci nonotes
    coefplot (est1, label("(Log) Base time") msymbol(+)) (est2, label("Any diag. time") msymbol(S)) ///
             (est3, label("(Log) diag. time")) (est4, label("Any diag. imag. test") msymbol(D)) ///
             (est5, label("Count of diag. imag. tests") msymbol(T)), ///
        keep(*langmatch_ext*) xline(0, lcol(red)) saving(figures/sa_age`g'_coef, replace)
    graph export figures/sa_age`g'_coef.eps, replace
}

// ---- Cost impact analysis by canton ----

// Step 1: Estimate adjusted per-patient cost difference (CHF)
reghdfe service_amount b0.langmatch $covariates, a(year month##medstat) vce(robust)

// Step 2: Retrieve coefficients for each contrast group
forvalues cat = 1/3 {
    scalar delta_`cat' = _b[`cat'.langmatch]
}

// Step 3: Scale up to canton level
preserve
    keep if e(sample)
    collapse (count) n = service_amount (sum) totalspend = service_amount, ///
        by(langmatch hosp_canton)

    gen cost_impact = 0
    forvalues cat = 1/3 {
        replace cost_impact = delta_`cat' * n if langmatch == `cat'
    }

    // Aggregate excess billing (CHF) across contrast groups within each canton
    // totalspend sums across all langmatch groups = total canton ED spend (denominator)
    collapse (sum) total_cost_impact_chf = cost_impact ///
             (sum) totalspend (sum) n_total = n, by(hosp_canton)
    gen perc_impact = round(total_cost_impact_chf / totalspend * 100, 0.01)

    // Crosswalk: canton abbreviation to BFS canton number (for shapefile merge)
    gen canton_id = .
    replace canton_id = 1  if hosp_canton == "ZH"
    replace canton_id = 2  if hosp_canton == "BE"
    replace canton_id = 3  if hosp_canton == "LU"
    replace canton_id = 4  if hosp_canton == "UR"
    replace canton_id = 5  if hosp_canton == "SZ"
    replace canton_id = 6  if hosp_canton == "OW"
    replace canton_id = 7  if hosp_canton == "NW"
    replace canton_id = 8  if hosp_canton == "GL"
    replace canton_id = 9  if hosp_canton == "ZG"
    replace canton_id = 10 if hosp_canton == "FR"
    replace canton_id = 11 if hosp_canton == "SO"
    replace canton_id = 12 if hosp_canton == "BS"
    replace canton_id = 13 if hosp_canton == "BL"
    replace canton_id = 14 if hosp_canton == "SH"
    replace canton_id = 15 if hosp_canton == "AR"
    replace canton_id = 16 if hosp_canton == "AI"
    replace canton_id = 17 if hosp_canton == "SG"
    replace canton_id = 18 if hosp_canton == "GR"
    replace canton_id = 19 if hosp_canton == "AG"
    replace canton_id = 20 if hosp_canton == "TG"
    replace canton_id = 21 if hosp_canton == "TI"
    replace canton_id = 22 if hosp_canton == "VD"
    replace canton_id = 23 if hosp_canton == "VS"
    replace canton_id = 24 if hosp_canton == "NE"
    replace canton_id = 25 if hosp_canton == "GE"
    replace canton_id = 26 if hosp_canton == "JU"

    list hosp_canton canton_id n_total total_cost_impact_chf perc_impact
    export excel "tables/cost_impact_canton.xlsx", firstrow(variables) replace
    save "$dataout/cost_impact_canton", replace
restore

// ---- Canton heatmap (spmap) ----
// Requires Swiss canton boundary shapefile converted once with:
//   shp2dta using "<path>/canton_boundary.shp", ///
//       database("$dataout/canton_db") coordinates("$dataout/canton_shp") ///
//       genid(shape_id) replace
//
// After conversion, check the abbreviation attribute name with:
//   use "$dataout/canton_db", clear
//   describe
// Common names: KUERZEL (swisstopo TLM), ABBR (FSO generalised).
// Adjust the rename line below accordingly.

use "$dataout/canton_db", clear
rename KUERZEL hosp_canton          // adjust to match your shapefile attribute
merge 1:1 hosp_canton using "$dataout/cost_impact_canton", keep(1 3) nogenerate

spmap perc_impact using "$dataout/canton_shp", id(shape_id)              ///
    fcolor(YlOrRd) ocolor(white ..) osize(thin ..)                        ///
    title("Cost impact of language mismatch by canton"                    ///
          "(% of total canton ED spend)", size(medlarge))                 ///
    legstyle(2) legend(pos(7) size(small))                                ///
    clmethod(quantile) clnumber(5)
graph export "figures/canton_heatmap.eps", replace
