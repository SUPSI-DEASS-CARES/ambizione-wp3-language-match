// Author: Igor Francetic
// Date: 20/11/2026
// This do-file is called by "master.do"

// Preliminaries

// Tariff descriptions
clear all
import excel "$rawdata/tariffs/Tariftyp_Liste_20241209.xlsx", sheet("Tariftyp-Liste") cellrange(A2:C122) firstrow allstring
drop if missing(Tariftyp)
rename (Tariftyp Status Tarifbezeichnung) (tariftype status tarifdes)
save "$dataout/tariftypes", replace
clear all
import excel "$rawdata/tariffs/tarmedtariffs.xlsx", sheet("tarmedtariffs") cellrange(A1:K5303) firstrow allstring
keep LNP Flag C ALPM Assi TLPT italiano
rename (LNP Flag C ALPM Assi TLPT italiano) (service_code flag visit_phase cost_a cost_b cost_c visit_setting)
order service_code flag visit_phase visit_setting cost_a cost_b cost_c
destring flag cost_a cost_b cost_c, replace
save "$dataout/tarmedtariffs", replace

// Prepare long-format files of ED visits for 2015-2022
clear all
forvalues x = 2015/2022 {
do exe/prepping`x'
}

// Prepare collapsed dataset
forvalues x=2015/2022 {
clear all
use "$dataout/`x'_long", clear
merge m:1 service_code using "$dataout/tarmedtariffs"
drop if _merge==2
drop _merge
do exe/covariates
do exe/genoutcomes
gen year=`x'
collapse (sum) service_amount anamnesistime diagnosistime diagimaging costs (firstnm) *canton  month year refsource gender_cd age_class medstat_reg_cd nationality grnation finregime, by(treatment_id is_vcode_aleat)
save "$dataout/`x'_collapsed", replace
}
forvalues x=2015/2021 {
append using "$dataout/`x'_collapsed"
}
sort year treatment_id is_vcode_aleat
forvalues x=2015/2022 {
erase "$dataout/`x'_collapsed.dta"
}
gen medstat_tertshare=.
gen medstat_secshare=.
gen medstat_compshare=.
forvalues x=2017/2022 {
merge m:1 year medstat_reg_cd  using "$dataout/medstateducation_`x'"
replace medstat_tertshare=tertiary_share if missing(medstat_tertshare)
replace medstat_secshare=secondary_share if missing(medstat_secshare)
replace medstat_compshare=compulsory_share if missing(medstat_compshare)
drop compulsory_share secondary_share tertiary_share
drop if _merge==2
drop _merge
}

// A few extra covariates
xtile quintile_tertiary=medstat_tertshare, nq(5)
egen medstat=group(medstat_reg_cd)
egen hcanton=group(hosp_canton)
egen pcanton=group(pat_canton)
gen swiss=(nationality==1)

// Apply exclusion criteria
gen flag_age=inlist(age_class, 0,5,10)
gen flag_refsource=inlist(refsource, 2,6,9)
gen flag_noanamnestime=(anamnesistime==0)
bysort is_vcode_aleat year month: gen temp=_N
gen flag_onepermonth=(temp==1)
drop temp

// Clean by dropping outliers
gen flag_outliers=.
sum anamnesistime, det
replace flag_outliers=1 if anamnesistime>`r(p99)'
sum diagnosistime, det
replace flag_outliers=1 if diagnosistime>`r(p99)'
sum diagimaging, det
replace flag_outliers=1 if diagimaging>`r(p99)'
sum costs, det
replace flag_outliers=1 if costs>`r(p99)'
tab flag_age
tab flag_refsource
tab flag_noanamnestime
tab flag_onepermonth
tab flag_outliers

// Define outcomes for analysis
gen any_basic=(anamnesistime>0)
gen time_basic=ln(anamnesistime)
gen any_diagact=(diagnosistime>0)
gen time_diagact=ln(diagnosistime)
gen any_diagtest=(diagimaging>0)
gen count_diagtest=ln(diagimaging)

// Define unique patient list to merge in comorbidities
preserve
bysort is_vcode_aleat (year month): gen counter=_n
keep if counter==1
keep is_vcode_aleat month year
duplicates drop is_vcode_aleat year, force
gen month_ed=month
gen year_ed=year
drop if missing(is_vcode_aleat)
save "$dataout/patlist_linkinpat", replace
restore

save "$dataout/temp", replace

// Define files with Elixhauser comorbidity score in the same year
forvalues x=2015/2022 {
clear all
import delimited "$rawms/DATA_BFS_MS_240521_`x'.DAT"
keep _0_0_v01 _0_2_v01a _1_2_v01m _4_2_v010 _4_2_v030 _4_2_v040 _4_2_v050 ///
_4_2_v060 _4_2_v070 _4_2_v080 _4_2_v090 _4_2_v100  _4_2_v110 _4_2_v120 _4_2_v130 _4_2_v140 _4_2_v150 _4_2_v160 _4_2_v170 ///
_4_2_v180  _4_2_v190 _4_2_v200 _4_2_v210 _4_2_v220 _4_2_v230 _4_2_v240 _4_2_v250 _4_2_v260 _4_2_v270
rename (_0_0_v01 _0_2_v01a _1_2_v01m _4_2_v010 _4_2_v030 _4_2_v040 _4_2_v050 ///
_4_2_v060 _4_2_v070 _4_2_v080 _4_2_v090 _4_2_v100  _4_2_v110 _4_2_v120 _4_2_v130 _4_2_v140 _4_2_v150 _4_2_v160 _4_2_v170 ///
 _4_2_v180  _4_2_v190 _4_2_v200 _4_2_v210 _4_2_v220 _4_2_v230 _4_2_v240 _4_2_v250 _4_2_v260) ///
(year is_vcode_aleat month diag1 diag2 diag3 diag4 diag5 diag6 diag7 diag8 diag9 diag10 diag11 diag12 ///
diag13 diag14 diag15 diag16 diag17 diag18 diag19 diag20 diag21 diag22 diag23 diag24 diag25)
merge m:1 is_vcode_aleat year using "$dataout/patlist_linkinpat"
keep if _merge==3
elix22 diag1-diag25, id(is_vcode_aleat)
gen year=`x'
save "$dataout/elix_`x'_0", replace
}

// Define files with Elixhauser comorbidity score in the year prior
forvalues x=2014/2021 {
clear all
import delimited "$rawms/DATA_BFS_MS_240521_`x'.DAT"
keep _0_0_v01 _0_2_v01a _1_2_v01m _4_2_v010 _4_2_v030 _4_2_v040 _4_2_v050 ///
_4_2_v060 _4_2_v070 _4_2_v080 _4_2_v090 _4_2_v100  _4_2_v110 _4_2_v120 _4_2_v130 _4_2_v140 _4_2_v150 _4_2_v160 _4_2_v170 ///
_4_2_v180  _4_2_v190 _4_2_v200 _4_2_v210 _4_2_v220 _4_2_v230 _4_2_v240 _4_2_v250 _4_2_v260 _4_2_v270
rename (_0_0_v01 _0_2_v01a _1_2_v01m _4_2_v010 _4_2_v030 _4_2_v040 _4_2_v050 ///
_4_2_v060 _4_2_v070 _4_2_v080 _4_2_v090 _4_2_v100  _4_2_v110 _4_2_v120 _4_2_v130 _4_2_v140 _4_2_v150 _4_2_v160 _4_2_v170 ///
 _4_2_v180  _4_2_v190 _4_2_v200 _4_2_v210 _4_2_v220 _4_2_v230 _4_2_v240 _4_2_v250 _4_2_v260) ///
(year is_vcode_aleat month diag1 diag2 diag3 diag4 diag5 diag6 diag7 diag8 diag9 diag10 diag11 diag12 ///
diag13 diag14 diag15 diag16 diag17 diag18 diag19 diag20 diag21 diag22 diag23 diag24 diag25)
replace year=year+1
merge m:1 is_vcode_aleat year using "$dataout/patlist_linkinpat"
keep if _merge==3
keep if month>=month_ed
elix22 diag1-diag25, id(is_vcode_aleat)
gen year=`x'+1
scalar fn=`x'+1
save "$dataout/elix_`=fn'_1", replace
}

// Define files with Elixhauser comorbidity score in the second year prior
forvalues x=2013/2020 {
clear all
import delimited "$rawms/DATA_BFS_MS_240521_`x'.DAT"
keep _0_0_v01 _0_2_v01a _1_2_v01m _4_2_v010 _4_2_v030 _4_2_v040 _4_2_v050 ///
_4_2_v060 _4_2_v070 _4_2_v080 _4_2_v090 _4_2_v100  _4_2_v110 _4_2_v120 _4_2_v130 _4_2_v140 _4_2_v150 _4_2_v160 _4_2_v170 ///
_4_2_v180  _4_2_v190 _4_2_v200 _4_2_v210 _4_2_v220 _4_2_v230 _4_2_v240 _4_2_v250 _4_2_v260 _4_2_v270
rename (_0_0_v01 _0_2_v01a _1_2_v01m _4_2_v010 _4_2_v030 _4_2_v040 _4_2_v050 ///
_4_2_v060 _4_2_v070 _4_2_v080 _4_2_v090 _4_2_v100  _4_2_v110 _4_2_v120 _4_2_v130 _4_2_v140 _4_2_v150 _4_2_v160 _4_2_v170 ///
 _4_2_v180  _4_2_v190 _4_2_v200 _4_2_v210 _4_2_v220 _4_2_v230 _4_2_v240 _4_2_v250 _4_2_v260) ///
(year is_vcode_aleat month diag1 diag2 diag3 diag4 diag5 diag6 diag7 diag8 diag9 diag10 diag11 diag12 ///
diag13 diag14 diag15 diag16 diag17 diag18 diag19 diag20 diag21 diag22 diag23 diag24 diag25)
replace year=year+2
merge m:1 is_vcode_aleat year using "$dataout/patlist_linkinpat"
keep if _merge==3
keep if month>=month_ed
elix22 diag1-diag25, id(is_vcode_aleat)
gen year=`x'+2
scalar fn=`x'+2
save "$dataout/elix_`=fn'_2", replace
}

// Take main dataset and merge in Elixhauser
clear all
use "$dataout/temp"
global comorb cmr_aids cmr_alcohol cmr_anemdef cmr_autoimmune cmr_bldloss cmr_cancer_leuk cmr_cancer_lymph cmr_cancer_mets cmr_cancer_nsitu cmr_cancer_solid cmr_cbvd cmr_coag cmr_dementia cmr_depress cmr_diab_cx cmr_diab_uncx cmr_drug_abuse cmr_hf cmr_htn_cx cmr_htn_uncx cmr_liver_mld cmr_liver_sev cmr_lung_chronic cmr_neuro_movt cmr_neuro_oth cmr_neuro_seiz cmr_obese cmr_paralysis cmr_perivasc cmr_psychoses cmr_pulmcirc cmr_renlfl_mod cmr_renlfl_sev cmr_thyroid_hypo cmr_thyroid_oth cmr_ulcer_peptic cmr_valve cmr_wghtloss
forvalues x=2015/2022 {
merge m:1 is_vcode_aleat year using "$dataout/elix_`x'_2", update
drop if _merge==2
drop _merge
erase "$dataout/elix_`x'_2.dta"
}
drop $comorb
rename elixsum elixsum2
forvalues x=2015/2022 {
merge m:1 is_vcode_aleat year using "$dataout/elix_`x'_1", update
drop if _merge==2
drop _merge
erase "$dataout/elix_`x'_1.dta"
}
drop $comorb
rename elixsum elixsum1
forvalues x=2015/2022 {
merge m:1 is_vcode_aleat year using "$dataout/elix_`x'_0", update
drop if _merge==2
drop _merge
erase "$dataout/elix_`x'_0.dta"
}
rename elixsum elixsum0
replace elixsum0=0 if missing(elixsum0)
replace elixsum1=0 if missing(elixsum1)
replace elixsum2=0 if missing(elixsum2)
egen elixsum_1y=rowmax(elixsum0 elixsum1)
egen elixsum_2y=rowmax(elixsum0 elixsum1 elixsum2)
drop elixsum0 elixsum1 elixsum2
tab elixsum_2y, m
gen any_hosp12=(elixsum_1y>0)

// Count ED visits in the 12 months prior to each observation
// Requires: ssc install rangestat
gen ymonth = (year - 2015) * 12 + month
gen one = 1
sort is_vcode_aleat ymonth
rangestat (sum) one, interval(ymonth -12 -1) by(is_vcode_aleat)
rename one_sum visits_prior12
drop one ymonth
replace visits_prior12 = 0 if missing(visits_prior12)
qui: sum visits_prior12, det
replace visits_prior12=`r(p99)' if visits_prior12>=`r(p99)'
replace visits_prior12=. if year==2015

// Label all relevant variables and save
do exe/labelling
save "$dataout/final", replace
erase "$dataout/temp.dta"
