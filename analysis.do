// =========================================================================
// analysis.do — ambizione-wp3
// Author : Igor Francetic
// Date   : 20/11/2026
// Purpose: Define exposure variables (langmatch, langmatch_ext), run all
//          regressions, and export tables and figures.
//
// Called by: master.do  (globals and $dataout/final.dta set by that file)
// Standalone: run master.do's setup block first (sets $main, $dataout, $shapefile, creates tables/ figures/).
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
// Same for descriptives
gen grouping=langmatch
label var grouping "Language match grouping"
label define grlab 0 "Swiss, matching" 1 "Swiss, non-matching" 2 "Non-Swiss, matching" 3 "Non-Swiss, non-matching"
label values grouping grlab


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

// Define mixed inpatient stay and comorbodity measure
gen hospcomorb=0 if elixsum_2y==0
replace hospcomorb=1 if elixsum_2y==1
replace hospcomorb=2 if elixsum_2y==2
replace hospcomorb=3 if elixsum_2y>2&elixsum_2y!=.
label define comlab 0 "No hospital stay" 1  "Stay with 1 Elixhauser co-morb." 2  "Stay with 2 Elixhauser co-morb." 3 "Stay with 3+ Elixhauser co-morb."
label values hospcomorb comlab
label var hospcomorb "Hospital stay and co-morbidities"

// Set globals
global covariates i.gender_cd##i.age_class b2.finregime i.refsource b0.visits_prior12 b0.hospcomorb
global outcomes anamnesistime diagnosistime diagimaging
global outcomes_descr i.any_basic anamnesistime i.any_diagact diagnosistime i.any_diagtest diagimaging costs

////////////////////////////////////////////////////////////////////////////////
// Descriptives
////////////////////////////////////////////////////////////////////////////////

// Sample restrictions
capture log close
log using restrictions, replace
preserve
count 
keep if flag_onepermonth==1
count
drop if flag_age==1
count
drop if flag_refsource==1
count
drop if flag_outliers==1
count
drop if year==2015
count
restore
log close
drop if year==2015
gen sample=1 if flag_onepermonth==1&flag_age!=1&flag_refsource!=1&flag_outliers!=1
tab sample

dtable $outcomes_descr i.gender_cd i.age_class i.finregime i.refsource i.visits_prior12 i.hospcomorb i.year if sample==1, by(grouping, notot) export("tables/table1.tex", replace tableonly) continuous(,statistics(mean sd median iqr)) factor(,statistics(fvfrequency fvpercent))
hist anamnesistime if sample==1, width(5) saving(figures/out1, replace) percent xtitle("Time (5 min bins)") title("Time on basic consultations") discrete
hist diagnosistime if sample==1, width(5) saving(figures/out2, replace) percent xtitle("Time (5 min bins)") title("Time on diagnostic activities") discrete
hist diagimaging if sample==1, saving(figures/out3, replace) percent xtitle("Count of tests ordered") title("Diagnostic tests ordered") discrete
hist costs if sample==1, saving(figures/out4, replace) percent xtitle("Swiss Francs") title("Billed amount")
graph combine figures/out1.gph figures/out2.gph  figures/out3.gph figures/out4.gph, row(2) 
graph export figures/fig2.eps, replace

////////////////////////////////////////////////////////////////////////////////
/****************************** Analyses **************************************/
////////////////////////////////////////////////////////////////////////////////

capture log close
log using analysis, replace

// Generate scalars for reference group means
sum anamnesistime if langmatch==0&sample==1
scalar av_anamnesistime = `r(mean)' 
sum diagnosistime if langmatch==0&sample==1
scalar av_diagnosistime = `r(mean)' 
sum diagimaging if langmatch==0&sample==1
scalar av_diagimaging = `r(mean)'
sum costs if langmatch==0&sample==1
scalar av_costs= `r(mean)' 

// 1. Unadjusted regressions
eststo clear
foreach var of global outcomes {
ppmlhdfe `var' b0.langmatch if sample==1, a(year month##medstat) vce(robust) d
eststo: margins r.langmatch, vce(unconditional) post
estadd scalar avgy=`=av_`var''
estadd local controls "No"
estadd local estm "Poisson"
estadd local season "Yes"
est save tables/unadj_`var', replace
}
eststo: reghdfe costs b0.langmatch if sample==1, a(year month##medstat) vce(robust)
estadd scalar avgy=`=av_costs'
estadd local controls "No"
estadd local estm "Linear"
estadd local season "Yes"
est save tables/unadj_costs, replace

esttab, keep(*langmatch*) ci label replace scalars(N avgy) mtitles("Basic consultation" "Diagnostic activities" "Diagnostic tests" "Billed amount") coeflabels(r1vs0.langmatch "Swiss, non-matching language" r2vs0.langmatch "Non-Swiss, matching language" r3vs0.langmatch "Non-Swiss, non-matching language") nobase
esttab using "tables/tabularsm2_unadj.tex",  keep(*langmatch*) label replace mtitles("Basic consultation" "Diagnostic activities" "Diagnostic tests" "Billed amount") scalars("controls Covariates" "estm Model" "season MedStat x Month seasonality" "N Observations" "avgy Outcome average for ref. group") nobase ci nonotes nobase

// 2. Regressions including covariates
eststo clear
foreach var of global outcomes {
eststo full_`var': ppmlhdfe `var' b0.langmatch $covariates if sample==1, a(year month##medstat) vce(robust) d
eststo: margins r.langmatch, vce(unconditional) post
estadd scalar avgy=`=av_`var''
estadd local controls "Yes"
estadd local estm "Poisson"
estadd local season "Yes"
est save tables/adj_`var', replace
}
eststo full_costs: reghdfe costs b0.langmatch $covariates if sample==1, a(year month##medstat) vce(robust)
estadd scalar avgy=`=av_costs'
estadd local controls "Yes"
estadd local estm "Linear"
estadd local season "Yes"
est save tables/adj_costs, replace
eststo: est use tables/adj_costs

* Export tables
esttab est*, keep(*langmatch*) ci label  scalars(N avgy) mtitles("Basic consultation" "Diagnostic activities" "Diagnostic tests" "Billed amount") coeflabels(r1vs0.langmatch "Swiss, non-matching language" r2vs0.langmatch "Non-Swiss, matching language" r3vs0.langmatch "Non-Swiss, non-matching language") nobase
esttab est* using "tables/tabular2_adj.tex", keep(*langmatch*) label replace scalars("controls Covariates" "estm Model" "season MedStat x Month seasonality" "N Observations" "avgy Outcome average for ref. group") mtitles("Basic consultation" "Diagnostic activities" "Diagnostic tests" "Billed amount") nobase ci nonotes coeflabels(r1vs0.langmatch "Swiss, non-matching language" r2vs0.langmatch "Non-Swiss, matching language" r3vs0.langmatch "Non-Swiss, non-matching language") 
esttab full_* using "tables/tabularsm3_full.tex", label replace scalars("N Observations") mtitles("Basic consultation" "Diagnostic activities" "Diagnostic tests" "Billed amount") nobase longtable nonote nobase

* Export main coefficient plot
eststo clear
foreach var of global outcomes {
eststo: est use tables/adj_`var'
}
coefplot (est1, label("Basic cons.") msymbol(+)) (est2, label("Diag. act.") msymbol(S)) (est3, label("Diag tests")) ///
, keep(*langmatch*) xline(0, lcol(red)) saving(figures/fig3, replace)  title("Main results") legend(pos(6) rows(1))  ///
coeflabels(r1vs0.langmatch = "Swiss, non-matching language" r2vs0.langmatch = "Non-Swiss, matching language" r3vs0.langmatch = "Non-Swiss, non-matching language") 
graph export figures/fig3.eps, replace

// 3. Split-sample regressions stratified by broad age group
* One table and one coefficient plot per age group (g=1: 15–39, 2: 40–69, 3: 70–79, 4: 80+)

eststo clear

forvalues g = 1/4 {
    foreach var of global outcomes {
        ppmlhdfe `var' b0.langmatch $covariates if agegroup == `g'&sample==1, a(year month##medstat) vce(robust) d
		eststo: margins r.langmatch, vce(unconditional) post
        qui: sum `var' if sample==1 & langmatch==0
        estadd scalar avgy=`r(mean)'
		estadd local controls "Yes"
		estadd local estm "Poisson"
        estadd local season "Yes"
        est save tables/age`g'_`var', replace
    }
	}

eststo clear
forvalues g = 1/4 {
foreach var of global outcomes {
eststo: est use tables/age`g'_`var'
}
}	
	esttab est1 est2 est3 using "tables/tabular_age1.tex", keep(*langmatch*) label replace ///
       mtitles("Basic consultation" "Diagnostic activities" "Diagnostic tests" "Billed amount") ///
        scalars("controls Covariates" "estm Model" "season MedStat x Month FE" "N Observations" "avgy Ref. group mean") ///
        nobase ci nonotes
	
	esttab est4 est5 est6 using "tables/tabular_age2.tex", keep(*langmatch*) label replace ///
        mtitles("Basic consultation" "Diagnostic activities" "Diagnostic tests" "Billed amount") ///
        scalars("controls Covariates" "estm Model" "season MedStat x Month FE" "N Observations" "avgy Ref. group mean") ///
        nobase ci nonotes
		
	esttab est7 est8 est9 using "tables/tabular_age3.tex", keep(*langmatch*) label replace ///
        mtitles("Basic consultation" "Diagnostic activities" "Diagnostic tests" "Billed amount") ///
        scalars("controls Covariates" "estm Model" "season MedStat x Month FE" "N Observations" "avgy Ref. group mean") ///
        nobase ci nonotes
		
	esttab est10 est11 est12 using "tables/tabular_age4.tex", keep(*langmatch*) label replace ///
        mtitles("Basic consultation" "Diagnostic activities" "Diagnostic tests" "Billed amount") ///
        scalars("controls Covariates" "estm Model" "season MedStat x Month FE" "N Observations" "avgy Ref. group mean") ///
        nobase ci nonotes
	
coefplot (est1, label("Basic cons.") msymbol(+)) (est2, label("Diag act.") msymbol(S)) (est3, label("Diag. tests")) ///
, legend(pos(6) rows(1))  xlabel(, angle(45))  ///
coeflabels(r1vs0.langmatch = "Swiss, non-matching language" r2vs0.langmatch = "Non-Swiss, matching language" r3vs0.langmatch = "Non-Swiss, non-matching language")  ///
keep(*langmatch*) xline(0, lcol(red)) title("Age 15-39") saving(figures/age1_coef, replace)
graph export figures/age1_coef.eps, replace
	
coefplot (est4, label("Basic cons.") msymbol(+)) (est5, label("Diag act.") msymbol(S)) (est6, label("Diag. tests"))  /// 
, legend(pos(6) rows(1))  xlabel(, angle(45))  ///
coeflabels(r1vs0.langmatch = "Swiss, non-matching language" r2vs0.langmatch = "Non-Swiss, matching language" r3vs0.langmatch = "Non-Swiss, non-matching language") ///
keep(*langmatch*) xline(0, lcol(red)) title("Age 40-69") saving(figures/age2_coef, replace)
graph export figures/age2_coef.eps, replace
	
coefplot (est7, label("Basic cons.") msymbol(+)) (est8, label("Diag act.") msymbol(S)) (est9, label("Diag. tests")) ///
, legend(pos(6) rows(1)) xlabel(, angle(45)) ///
coeflabels(r1vs0.langmatch = "Swiss, non-matching language" r2vs0.langmatch = "Non-Swiss, matching language" r3vs0.langmatch = "Non-Swiss, non-matching language") ///
keep(*langmatch*) xline(0, lcol(red)) title("Age 70-79") saving(figures/age3_coef, replace)
    graph export figures/age3_coef.eps, replace
	
coefplot (est10, label("Basic cons.") msymbol(+)) (est11, label("Diag act.") msymbol(S)) (est12, label("Diag. tests")) ///
, legend(off) xlabel(, angle(45)) ///
coeflabels(r1vs0.langmatch = "Swiss, non-matching language" r2vs0.langmatch = "Non-Swiss, matching language" r3vs0.langmatch = "Non-Swiss, non-matching language") ///
keep(*langmatch*) xline(0, lcol(red)) title("Age 80+") saving(figures/age4_coef, replace)
graph export figures/age4_coef.eps, replace

// 4. ---- No outlier and refsource exclusion -----

gen sens_sample=1 if flag_onepermonth==1&flag_age!=1&flag_refsource!=1
eststo clear
foreach var of global outcomes {
ppmlhdfe `var' b0.langmatch $covariates if sens_sample==1, a(year month##medstat) vce(robust) d
eststo: margins r.langmatch, vce(unconditional) post
estadd scalar avgy=`=av_`var''
estadd local controls "Yes"
estadd local estm "Poisson"
estadd local season "Yes"
est save tables/sens_`var', replace
}
eststo: reghdfe costs b0.langmatch $covariates if sens_sample==1, a(year month##medstat) vce(robust)
estadd scalar avgy=`=av_costs'
estadd local controls "Yes"
estadd local estm "Linear"
estadd local season "Yes"
est save tables/sens_costs, replace

* Export tables
esttab est*, label keep(*langmatch*) replace scalars("controls Covariates" "estm Model" "season MedStat x Month seasonality" "N Observations" "avgy Outcome average for ref. group") mtitles("Basic consultation" "Diagnostic activities" "Diagnostic tests" "Billed amount") nobase ci nonotes coeflabels(r1vs0.langmatch "Swiss, non-matching language" r2vs0.langmatch "Non-Swiss, matching language" r3vs0.langmatch "Non-Swiss, non-matching language") 
esttab est* using "tables/sens_adj.tex", longtable label replace scalars("controls Covariates" "estm Model" "season MedStat x Month seasonality" "N Observations" "avgy Outcome average for ref. group") mtitles("Basic consultation" "Diagnostic activities" "Diagnostic tests" "Billed amount") nobase ci nonotes coeflabels(r1vs0.langmatch "Swiss, non-matching language" r2vs0.langmatch "Non-Swiss, matching language" r3vs0.langmatch "Non-Swiss, non-matching language") 

// 5. Cost impact analysis by canton ----

eststo clear

* Step 1: Estimate adjusted per-patient cost difference (CHF)
est use tables/adj_costs

* Step 2: Retrieve coefficients for each contrast group
forvalues cat = 1/3 {
    scalar delta_`cat' = _b[`cat'.langmatch]
}

* Step 3: Scale up to canton level
preserve
    keep if sample==1
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

// 6. ---- Canton heatmap (spmap) ----
// Converts the swisstopo shapefile once; skipped if the converted files already exist.
// Shapefile is NOT in the repo (licensed data): set $shapefile in master.do.
capture confirm file "$dataout/canton_db.dta"
if _rc {
    shp2dta using "$shapefile", ///
        database("$dataout/canton_db") coordinates("$dataout/canton_shp") ///
        genid(shape_id) replace
}

use "$dataout/canton_db", clear
rename KANTONSNUM canton_id
merge 1:1 canton_id using "$dataout/cost_impact_canton", keep(1 3) nogenerate

spmap perc_impact using "$dataout/canton_shp", id(shape_id)              ///
    fcolor(YlOrRd) ocolor(black ..) osize(thin ..)                        ///
    title("% of total canton ED spend for the target population and ED visit phases", size(medlarge))                 ///
    legstyle(1) legend(pos(11) size(small))                                ///
    clmethod(quantile) clnumber(5)
graph export "figures/canton_heatmap.eps", replace

log close