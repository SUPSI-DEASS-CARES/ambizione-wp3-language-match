// Author: Igor Francetic
// Date: 19/02/2026
// This do-file is called by "analysis.do"

// Preliminaries

// Tariff descriptions
clear all
import excel "T:\AMBIZIONE\Data\PSA\Tariftyp_Liste_20241209.xlsx", sheet("Tariftyp-Liste") cellrange(A2:C122) firstrow allstring
drop if missing(Tariftyp)
rename (Tariftyp Status Tarifbezeichnung) (tariftype status tarifdes)
save "$dataout\tariftypes", replace
clear all
import excel "T:\AMBIZIONE\Data\Tariffs\tarmedtariffs.xlsx", sheet("tarmedtariffs") cellrange(A1:K5303) firstrow allstring
keep LNP Flag C ALPM Assi TLPT italiano
rename (LNP Flag C ALPM Assi TLPT italiano) (service_code flag visit_phase cost_a cost_b cost_c visit_setting)
order service_code flag visit_phase visit_setting cost_a cost_b cost_c
destring flag cost_a cost_b cost_c, replace
save "$dataout\tarmedtariffs", replace

// Area-level (Medstat region) educational achievement
forvalues x=2017/2022 {
clear all
import delimited dataout/medstateducation_`x'.csv,   varnames(1)  asdoubl 
rename 	region_id medstat_reg_cd
destring compulsory_share secondary_share tertiary_share, replace dpcomma
gen year=`x'
save dataout/medstateducation_`x', replace
}

// Prepare long-format files of ED visits for 2015-2022
clear all
forvalues x = 2015/2022 {
do prepping`x'
}

// Prepare collapsed dataset
forvalues x=2015/2022 {
clear all
use "$dataout/`x'_long", clear
merge m:1 service_code using $dataout/tarmedtariffs
drop if _merge==2
drop _merge
do covariates
do genoutcomes
gen year=`x'
collapse (sum) service_amount anamnesistime diagnosistime diagimaging (firstnm) *canton  month year refsource gender_cd age_class medstat_reg_cd nationality grnation finregime, by(treatment_id is_vcode_aleat)
save "$dataout/`x'_collapsed", replace
}
forvalues x=2015/2021 {
append using "$dataout/`x'_collapsed"
}
sort year treatment_id is_vcode_aleat
forvalues x=2015/2022 {
erase $dataout/`x'_collapsed.dta
}
gen medstat_tertshare=.
gen medstat_secshare=.
gen medstat_compshare=.
forvalues x=2017/2022 {
merge m:1 year medstat_reg_cd  using dataout/medstateducation_`x'
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
drop if inlist(age_class, 0,5,10)
drop if inlist(refsource, 2,6,9)
drop if anamnesistime==0

// Clean by dropping outliers
gen temp=.
sum anamnesistime, det
replace temp=1 if anamnesistime>`r(p99)'
sum diagnosistime, det
replace temp=1 if diagnosistime>`r(p99)'
sum diagimaging, det
replace temp=1 if diagimaging>`r(p99)'
drop if temp==1
drop temp

// Define outcomes for analysis
gen time_basic=ln(anamnesistime)
gen any_diagact=(diagnosistime>0)
gen time_diagact=ln(diagnosistime)
gen any_diagtest=(diagimaging>0)
gen count_diagtest=diagimaging if diagimaging>0

// Define unique patient list to merge in comorbidities
preserve
bysort is_vcode_aleat (year month): gen counter=_n
keep if counter==1
keep is_vcode_aleat month year
duplicates drop is_vcode_aleat year, force
gen month_ed=month
gen year_ed=year
drop if missing(is_vcode_aleat)
save dataout/patlist_linkinpat, replace
restore

save "$dataout/temp", replace

// Define files with Elixhauser comorbidity score in the same year
forvalues x=2015/2022 {
clear all
import delimited "$rawms\DATA_BFS_MS_240521_`x'.DAT"
keep _0_0_v01 _0_2_v01a _1_2_v01m _4_2_v010 _4_2_v030 _4_2_v040 _4_2_v050 ///
_4_2_v060 _4_2_v070 _4_2_v080 _4_2_v090 _4_2_v100  _4_2_v110 _4_2_v120 _4_2_v130 _4_2_v140 _4_2_v150 _4_2_v160 _4_2_v170 ///
_4_2_v180  _4_2_v190 _4_2_v200 _4_2_v210 _4_2_v220 _4_2_v230 _4_2_v240 _4_2_v250 _4_2_v260 _4_2_v270
rename (_0_0_v01 _0_2_v01a _1_2_v01m _4_2_v010 _4_2_v030 _4_2_v040 _4_2_v050 ///
_4_2_v060 _4_2_v070 _4_2_v080 _4_2_v090 _4_2_v100  _4_2_v110 _4_2_v120 _4_2_v130 _4_2_v140 _4_2_v150 _4_2_v160 _4_2_v170 ///
 _4_2_v180  _4_2_v190 _4_2_v200 _4_2_v210 _4_2_v220 _4_2_v230 _4_2_v240 _4_2_v250 _4_2_v260) ///
(year is_vcode_aleat month diag1 diag2 diag3 diag4 diag5 diag6 diag7 diag8 diag9 diag10 diag11 diag12 ///
diag13 diag14 diag15 diag16 diag17 diag18 diag19 diag20 diag21 diag22 diag23 diag24 diag25)
merge m:1 is_vcode_aleat year using dataout/patlist_linkinpat
keep if _merge==3
elix22 diag1-diag25, id(is_vcode_aleat)
gen year=`x'
save dataout/elix_`x'_0, replace
}

// Define files with Elixhauser comorbidity score in the year prior
forvalues x=2014/2021 {
clear all
import delimited "$rawms\DATA_BFS_MS_240521_`x'.DAT"
keep _0_0_v01 _0_2_v01a _1_2_v01m _4_2_v010 _4_2_v030 _4_2_v040 _4_2_v050 ///
_4_2_v060 _4_2_v070 _4_2_v080 _4_2_v090 _4_2_v100  _4_2_v110 _4_2_v120 _4_2_v130 _4_2_v140 _4_2_v150 _4_2_v160 _4_2_v170 ///
_4_2_v180  _4_2_v190 _4_2_v200 _4_2_v210 _4_2_v220 _4_2_v230 _4_2_v240 _4_2_v250 _4_2_v260 _4_2_v270
rename (_0_0_v01 _0_2_v01a _1_2_v01m _4_2_v010 _4_2_v030 _4_2_v040 _4_2_v050 ///
_4_2_v060 _4_2_v070 _4_2_v080 _4_2_v090 _4_2_v100  _4_2_v110 _4_2_v120 _4_2_v130 _4_2_v140 _4_2_v150 _4_2_v160 _4_2_v170 ///
 _4_2_v180  _4_2_v190 _4_2_v200 _4_2_v210 _4_2_v220 _4_2_v230 _4_2_v240 _4_2_v250 _4_2_v260) ///
(year is_vcode_aleat month diag1 diag2 diag3 diag4 diag5 diag6 diag7 diag8 diag9 diag10 diag11 diag12 ///
diag13 diag14 diag15 diag16 diag17 diag18 diag19 diag20 diag21 diag22 diag23 diag24 diag25)
replace year=year+1
merge m:1 is_vcode_aleat year using dataout/patlist_linkinpat
keep if _merge==3
keep if month>=month_ed
elix22 diag1-diag25, id(is_vcode_aleat)
gen year=`x'+1
scalar fn=`x'+1
save dataout/elix_`=fn'_1, replace
}

// Define files with Elixhauser comorbidity score two years prior
forvalues x=2013/2020 {
clear all
import delimited "$rawms\DATA_BFS_MS_240521_`x'.DAT"
keep _0_0_v01 _0_2_v01a _1_2_v01m _4_2_v010 _4_2_v030 _4_2_v040 _4_2_v050 ///
_4_2_v060 _4_2_v070 _4_2_v080 _4_2_v090 _4_2_v100  _4_2_v110 _4_2_v120 _4_2_v130 _4_2_v140 _4_2_v150 _4_2_v160 _4_2_v170 ///
_4_2_v180  _4_2_v190 _4_2_v200 _4_2_v210 _4_2_v220 _4_2_v230 _4_2_v240 _4_2_v250 _4_2_v260 _4_2_v270
rename (_0_0_v01 _0_2_v01a _1_2_v01m _4_2_v010 _4_2_v030 _4_2_v040 _4_2_v050 ///
_4_2_v060 _4_2_v070 _4_2_v080 _4_2_v090 _4_2_v100  _4_2_v110 _4_2_v120 _4_2_v130 _4_2_v140 _4_2_v150 _4_2_v160 _4_2_v170 ///
 _4_2_v180  _4_2_v190 _4_2_v200 _4_2_v210 _4_2_v220 _4_2_v230 _4_2_v240 _4_2_v250 _4_2_v260) ///
(year is_vcode_aleat month diag1 diag2 diag3 diag4 diag5 diag6 diag7 diag8 diag9 diag10 diag11 diag12 ///
diag13 diag14 diag15 diag16 diag17 diag18 diag19 diag20 diag21 diag22 diag23 diag24 diag25)
replace year=year+2
merge m:1 is_vcode_aleat year using dataout/patlist_linkinpat
keep if _merge==3
keep if month>=month_ed
elix22 diag1-diag25, id(is_vcode_aleat)
gen year=`x'+2
scalar fn=`x'+2
save dataout/elix_`=fn'_2, replace
}

// Define files with Elixhauser comorbidity score three years prior
forvalues x=2012/2019 {
clear all
import delimited "$rawms\DATA_BFS_MS_240521_`x'.DAT"
keep _0_0_v01 _0_2_v01a _1_2_v01m _4_2_v010 _4_2_v030 _4_2_v040 _4_2_v050 ///
_4_2_v060 _4_2_v070 _4_2_v080 _4_2_v090 _4_2_v100  _4_2_v110 _4_2_v120 _4_2_v130 _4_2_v140 _4_2_v150 _4_2_v160 _4_2_v170 ///
_4_2_v180  _4_2_v190 _4_2_v200 _4_2_v210 _4_2_v220 _4_2_v230 _4_2_v240 _4_2_v250 _4_2_v260 _4_2_v270
rename (_0_0_v01 _0_2_v01a _1_2_v01m _4_2_v010 _4_2_v030 _4_2_v040 _4_2_v050 ///
_4_2_v060 _4_2_v070 _4_2_v080 _4_2_v090 _4_2_v100  _4_2_v110 _4_2_v120 _4_2_v130 _4_2_v140 _4_2_v150 _4_2_v160 _4_2_v170 ///
 _4_2_v180  _4_2_v190 _4_2_v200 _4_2_v210 _4_2_v220 _4_2_v230 _4_2_v240 _4_2_v250 _4_2_v260) ///
(year is_vcode_aleat month diag1 diag2 diag3 diag4 diag5 diag6 diag7 diag8 diag9 diag10 diag11 diag12 ///
diag13 diag14 diag15 diag16 diag17 diag18 diag19 diag20 diag21 diag22 diag23 diag24 diag25)
replace year=year+3
merge m:1 is_vcode_aleat year using dataout/patlist_linkinpat
keep if _merge==3
keep if month>=month_ed
elix22 diag1-diag25, id(is_vcode_aleat)
gen year=`x'+3
scalar fn=`x'+3
save dataout/elix_`=fn'_3, replace
}

// Take main dataset and merge in Elixhauser
global comorb cmr_aids cmr_alcohol cmr_anemdef cmr_autoimmune cmr_bldloss cmr_cancer_leuk cmr_cancer_lymph cmr_cancer_mets cmr_cancer_nsitu cmr_cancer_solid cmr_cbvd cmr_coag cmr_dementia cmr_depress cmr_diab_cx cmr_diab_uncx cmr_drug_abuse cmr_hf cmr_htn_cx cmr_htn_uncx cmr_liver_mld cmr_liver_sev cmr_lung_chronic cmr_neuro_movt cmr_neuro_oth cmr_neuro_seiz cmr_obese cmr_paralysis cmr_perivasc cmr_psychoses cmr_pulmcirc cmr_renlfl_mod cmr_renlfl_sev cmr_thyroid_hypo cmr_thyroid_oth cmr_ulcer_peptic cmr_valve cmr_wghtloss
clear all
use $dataout/temp, clear
forvalues x=2015/2022 {
merge m:1 is_vcode_aleat year using dataout/elix_`x'_3, update
drop if _merge==3
drop _merge
erase "$dataout/elix_`x'_3.dta"
}
drop $comorb
rename elixsum elixsum3
forvalues x=2015/2022 {
merge m:1 is_vcode_aleat year using dataout/elix_`x'_2, update
drop if _merge==2
drop _merge
erase "$dataout/elix_`x'_2.dta"
}
drop $comorb
rename elixsum elixsum2
forvalues x=2015/2022 {
merge m:1 is_vcode_aleat year using dataout/elix_`x'_1, update
drop if _merge==2
drop _merge
erase "$dataout/elix_`x'_1.dta"
}
drop $comorb
rename elixsum elixsum1
forvalues x=2015/2022 {
merge m:1 is_vcode_aleat year using dataout/elix_`x'_0, update
drop if _merge==2
drop _merge
erase "$dataout/elix_`x'_0.dta"
}
drop $comorb
rename elixsum elixsum0
replace elixsum0=0 if missing(elixsum0)
replace elixsum1=0 if missing(elixsum1)
replace elixsum2=0 if missing(elixsum2)
replace elixsum3=0 if missing(elixsum3)
egen elixsum_3y=rowmax(elixsum0 elixsum1 elixsum2 elixsum3)
drop elixsum0 elixsum1 elixsum2 elixsum3
tab elixsum_3y, m


// Count ED visits in the 12 months prior to each observation
// Requires: ssc install rangestat
gen ymonth = (year - 2015) * 12 + month
gen one = 1
sort is_vcode_aleat ymonth
rangestat (sum) one, interval(ymonth -12 -1) by(is_vcode_aleat)
rename one_sum visits_prior12
drop one ymonth
replace visits_prior12 = 0 if missing(visits_prior12)

// Label all relevant variables and save
do labelling
save "$dataout/final", replace
erase "$dataout/temp.dta"

/*
// Define file with length of stay
forvalues x=2014/2021 {
clear all
import delimited "$rawms\DATA_BFS_MS_240521_`x'.DAT"
keep _0_0_v01 _0_2_v01a _0_0_v05_2 _1_2_v01m 
rename (_0_0_v01 _0_2_v01a _0_0_v05_2 _1_2_v01m) (year is_vcode_aleat los month)
replace year=year+1
merge m:1 is_vcode_aleat year using dataout/patlist_linkinpat
keep if _merge==3
keep if month>=month_ed
replace year=year+1
collapse (sum) los (firstnm) month year, by(is_vcode_aleat)
scalar fn=`x'+1
save dataout/los_`=fn', replace
}

// Merge in length of stay
clear all
use "$dataout/final", replace
forvalues x=2015/2022 {
merge m:1 is_vcode_aleat year using dataout/los_`x', update
drop _merge
}
replace los=0 if missing(los)
tab los, m
gen anyhospital=(los>0)
sum los if anyhospital==1, det
replace los=`r(p99)' if los>`r(p99)'

save "$dataout/final", replace
