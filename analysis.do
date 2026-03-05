// =========================================================================
// analysis.do — ambizione-wp3
// Author : Igor Francetic
// Date   : 19/02/2026
// Purpose: Define exposure variables (langmatch, langmatch_ext), run all
//          regressions, and export tables and figures.
//
// Called by: master.do  (globals and $dataout/final.dta set by that file)
//
// Standalone use (if running this file directly without master.do):
//   Ensure the following are set before do-ing this file:
//     sysdir set PLUS     "E:\Users\igor.francetic\ado\plus\"
//     sysdir set PERSONAL "E:\Users\igor.francetic\ado\personal\"
//     global datain  "T:\AMBIZIONE\Data\PSA\raw"
//     global dataout "T:\AMBIZIONE\WP3\Igor\dataout"
//     global rawms   "T:\AMBIZIONE\Data\MS\raw\"
//     global main    "T:\AMBIZIONE\WP3\Igor"
//     cd "$main"
//   and that $dataout/final.dta already exists (produced by prepping.do).
// =========================================================================

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
global covariates i.gender_cd##i.age_class b2.finregime i.refsource b0.visits_prior12 b0.any_hosp12
global outcomes time_basic any_diagact time_diagact any_diagtest count_diagtest
global outcomes_descr anamnesistime i.any_diagact diagnosistime i.any_diagtest diagimaging

// Descriptives
gen grouping=langmatch
label var grouping "Language match grouping"
label define grlab 0 "Swiss, matching" 1 "Swiss, non-matching" 2 "Non-Swiss, matching" 3 "Non-Swiss, non-matching"
label values grouping grlab
dtable $outcomes_descr i.gender i.age_class i.finregime i.refsource visits_prior12 i.any_hosp12 i.year if year!=2015, by(grouping, notot) export("tables/table1.tex", replace tableonly) 
hist anamnesistime, width(5) saving(figures/out1, replace) percent xtitle("Time (5 min bins)") title("Time on basic consultations") discrete
hist diagnosistime if diagnosistime>0, width(3) saving(figures/out2, replace) percent xtitle("Time (3 min bins)") title("Time on diagnostic activities") discrete
hist diagimaging if diagimaging>0, saving(figures/out3, replace) percent xtitle("Count of tests ordered") title("Diagnostic tests ordered") discrete
graph combine figures/out1.gph figures/out2.gph figures/out3.gph, row(1) ycommon
graph export figures/fig2.eps, replace

////////////////////////////////////////////////////////////////////////////////
/****************************** Analyses **************************************/
////////////////////////////////////////////////////////////////////////////////

// Generate scalars for reference group means
sum anamnesistime if langmatch==0
scalar av_time_basic = `r(mean)' 
sum any_diagact if langmatch==0
scalar av_any_diagact = `r(mean)' 
sum diagnosistime if langmatch==0&diagnosistime>0
scalar av_time_diagact = `r(mean)' 
sum any_diagtest if langmatch==0
scalar av_any_diagtest = `r(mean)' 
sum diagimaging if langmatch==0&diagimaging>0
scalar av_count_diagtest = `r(mean)' 

// 1. Unadjusted regressions
eststo clear
foreach var of global outcomes {
eststo: reghdfe `var' b0.langmatch, a(year month##medstat) vce(robust)
estadd scalar avgy=`=av_`var''
estadd local controls "No"
estadd local season "Yes"
est save tables/unadj_`var', replace
}
esttab, keep(*langmatch*) label replace scalars(N avgy) mtitles("(Log) Base time" "Any diag. time" "(Log) diag time" "Any diag. imag. test" "(Log) diag. tests")
esttab using "tables\tabularsm2_unadj.tex", keep(*langmatch*) label replace mtitles("Base time" "Any diag. time" "(Log) diag time" "Any diag. test" "(Log) diag. tests") scalars("controls Covariates" "season MedStat x Month seasonality" "N Observations" "avgy Outcome average for ref. group") nobase ci nonotes

// 2. Regressions including covariates
eststo clear
foreach var of global outcomes {
eststo: reghdfe `var' b0.langmatch $covariates, a(year month##medstat) vce(robust)
estadd scalar avgy=`=av_`var''
estadd local controls "No"
estadd local season "Yes"
est save tables/adj_`var', replace
}

* Export tables
esttab *, keep(*langmatch*) label replace scalars(N avgy) mtitles("(Log) Base time" "Any diag. time" "(Log) diag. time" "Any diag. test" "(Log) diag. tests") 
esttab * using "tables\tabular2_adj.tex", keep(*langmatch*) label replace scalars("controls Covariates" "season MedStat x Month seasonality" "N Observations" "avgy Outcome average for ref. group") mtitles("(Log) Base time" "Any diag. time" "(Log) diag. time" "Any diag. test" "(Log) diag. tests") nobase ci nonotes
esttab * using "tables\tabularsm3_full.tex", label replace scalars("N Observations") mtitles("(Log) Base time" "Any diag. time" "(Log) diag. time" "Any diag. test" "(Log) diag. tests") nobase longtable nonote

* Export main coefficient plot
coefplot (est1, label("(Log) Base time") msymbol(+)) (est2, label("Any diag. time") msymbol(S)) (est3, label("(Log) diag. time")) ///
(est4, label("Any diag. test") msymbol(D)) (est5, label("(Log) diag. tests") msymbol(T)), keep(*langmatch*) xline(0, lcol(red)) saving(figures/fig3, replace) legend(pos(6)) title("Main results") xscale(range(-0.025 0.055)) xlabel(-0.025(0.005)0.055, angle(45))
graph export figures/fig3.eps, replace

// 3. Split-sample regressions stratified by broad age group
* One table and one coefficient plot per age group (g=1: 15–39, 2: 40–69, 3: 70–79, 4: 80+)
forvalues g = 2/4 {
    foreach var of global outcomes {
        eststo: reghdfe `var' b0.langmatch $covariates if agegroup == `g', a(year month##medstat) vce(robust)
        qui: sum `var' if e(sample)==1 & langmatch==0
        estadd scalar avgy=`=av_`var''
		estadd local controls "Yes"
        estadd local season "Yes"
        est save tables/age`g'_`var', replace
    }
	}
	
	esttab est1 est2 est3 est4 est5 using "tables/tabular_age1.tex", keep(*langmatch*) label replace ///
        mtitles("(Log) Base time" "Any diag. time" "(Log) diag time" "Any diag. imag. test" "(Log) diag. tests") ///
        scalars("controls Covariates" "season MedStat x Month FE" "N Observations" "avgy Ref. group mean") ///
        nobase ci nonotes
	
	esttab est6 est7 est8 est9 est10 using "tables/tabular_age2.tex", keep(*langmatch*) label replace ///
        mtitles("(Log) Base time" "Any diag. time" "(Log) diag time" "Any diag. imag. test" "(Log) diag. tests") ///
        scalars("controls Covariates" "season MedStat x Month FE" "N Observations" "avgy Ref. group mean") ///
        nobase ci nonotes
		
	esttab est11 est12 est13 est14 est15 using "tables/tabular_age3.tex", keep(*langmatch*) label replace ///
        mtitles("(Log) Base time" "Any diag. time" "(Log) diag time" "Any diag. imag. test" "(Log) diag. tests") ///
        scalars("controls Covariates" "season MedStat x Month FE" "N Observations" "avgy Ref. group mean") ///
        nobase ci nonotes
		
	esttab est16 est17 est18 est19 est20 using "tables/tabular_age4.tex", keep(*langmatch*) label replace ///
        mtitles("(Log) Base time" "Any diag. time" "(Log) diag time" "Any diag. imag. test" "(Log) diag. tests") ///
        scalars("controls Covariates" "season MedStat x Month FE" "N Observations" "avgy Ref. group mean") ///
        nobase ci nonotes
	
	coefplot (est1, label("(Log) Base time") msymbol(+)) (est2, label("Any diag. time") msymbol(S)) ///
             (est3, label("(Log) diag. time")) (est4, label("Any diag. imag. test") msymbol(D)) ///
             (est5, label("(Log) diag. tests ") msymbol(T)), legend(off) xscale(range(-0.025 0.055)) xlabel(-0.025(0.005)0.055, angle(45)) ///
        keep(*langmatch*) xline(0, lcol(red)) title("Age 16-39") saving(figures/age1_coef, replace)
    graph export figures/age1_coef.eps, replace
	
	coefplot (est6, label("(Log) Base time") msymbol(+)) (est7, label("Any diag. time") msymbol(S)) ///
             (est8, label("(Log) diag. time")) (est9, label("Any diag. imag. test") msymbol(D)) ///
             (est10, label("(Log) diag. tests ") msymbol(T)), legend(off) xscale(range(-0.025 0.055)) xlabel(-0.025(0.005)0.055, angle(45))  ///
        keep(*langmatch*) xline(0, lcol(red)) title("Age 40-69") saving(figures/age2_coef, replace)
    graph export figures/age2_coef.eps, replace
	
	coefplot (est11, label("(Log) Base time") msymbol(+)) (est12, label("Any diag. time") msymbol(S)) ///
             (est13, label("(Log) diag. time")) (est14, label("Any diag. imag. test") msymbol(D)) ///
             (est15, label("(Log) diag. tests") msymbol(T)), legend(off) xscale(range(-0.025 0.055)) xlabel(-0.025(0.005)0.055, angle(45)) ///
        keep(*langmatch*) xline(0, lcol(red)) title("Age 70-79") saving(figures/age3_coef, replace)
    graph export figures/age3_coef.eps, replace
	
	coefplot (est16, label("(Log) Base time") msymbol(+)) (est17, label("Any diag. time") msymbol(S)) ///
             (est18, label("(Log) diag. time")) (est19, label("Any diag. imag. test") msymbol(D)) ///
             (est20, label("(Log) diag. tests") msymbol(T)), legend(off) xscale(range(-0.025 0.055)) xlabel(-0.025(0.005)0.055, angle(45)) ///
        keep(*langmatch*) xline(0, lcol(red)) title("Age 80+") saving(figures/age4_coef, replace)
    graph export figures/age4_coef.eps, replace

graph combine "figures/age1_coef.gph" "figures/age2_coef.gph" "figures/age3_coef.gph" "figures/age4_coef.gph", ///
col(2) ycommon xsize(30) ysize(30) saving(figures/fig4, replace)
graph export figures/fig4.eps, replace

// 4. Cost impact analysis by canton ----

* Step 1: Estimate adjusted per-patient cost difference (CHF)
reghdfe costs b0.langmatch $covariates, a(year month##medstat) vce(robust)

* Step 2: Retrieve coefficients for each contrast group
forvalues cat = 1/3 {
    scalar delta_`cat' = _b[`cat'.langmatch]
}

* Step 3: Scale up to canton level
preserve
    keep if e(sample)
    collapse (count) n = service_amount (sum) totalspend = service_amount, ///
        by(langmatch hosp_canton)

    gen cost_impact = 0
    forvalues cat = 1/3 {
        replace cost_impact = delta_`cat' * n if langmatch == `cat'
    }

    * Aggregate excess billing (CHF) across contrast groups within each canton
    *totalspend sums across all langmatch groups = total canton ED spend (denominator)
    collapse (sum) total_cost_impact_chf = cost_impact ///
             (sum) totalspend (sum) n_total = n, by(hosp_canton)
    gen perc_impact = round(total_cost_impact_chf / totalspend * 100, 0.01)

    * Crosswalk: canton abbreviation to BFS canton number (for shapefile merge)
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

    list hosp_canton total_cost_impact_chf perc_impact
    export excel "tables/cost_impact_canton.xlsx", firstrow(variables) replace
	listtex hosp_canton total_cost_impact_chf perc_impact using "tables/cost_impact_canton.tex", rstyle(tabular) replace
    save "$dataout/cost_impact_canton", replace
restore

// 5. ---- Canton heatmap (spmap) ----
// Run shp2dta once to convert the shapefile; comment out after first run.
shp2dta using "T:/AMBIZIONE/Data/boundaries/swissBOUNDARIES3D_1_5_TLM_KANTONSGEBIET.shp", ///
    database("$dataout/canton_db") coordinates("$dataout/canton_shp")     ///
    genid(shape_id) replace

use "$dataout/canton_db", clear
rename KANTONSNUM canton_id
merge 1:1 canton_id using "$dataout/cost_impact_canton", keep(1 3) nogenerate

spmap perc_impact using "$dataout/canton_shp", id(shape_id)              ///
    fcolor(YlOrRd) ocolor(black ..) osize(thin ..)                        ///
    title("% of total canton ED spend for the target population and ED visit phases", size(medlarge))                 ///
    legstyle(1) legend(pos(11) size(small))                                ///
    clmethod(quantile) clnumber(5)
graph export "figures/canton_heatmap.eps", replace
