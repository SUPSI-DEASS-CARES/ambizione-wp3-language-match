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

// ED attendances in previous year
preserve
keep is_vcode_aleat year month
duplicates drop is_vcode_aleat year, force
gen ref_year=year-1
drop if year==2015
forvalues x=2015/2021 {
merge 1:m is_vcode_aleat ref_year using $dataout/`x'_patients, keepusing(treat_dt_beg)
keep if _merge==3
drop _merge
gen monthstr_old=substr(treat_dt_beg, 1, 3)
gen month_old=.
replace month_old=1 if monthstr=="JAN"
replace month_old=2 if monthstr=="FEB"
replace month_old=3 if monthstr=="MAR"
replace month_old=4 if monthstr=="APR"
replace month_old=5 if monthstr=="MAY"
replace month_old=6 if monthstr=="JUN"
replace month_old=7 if monthstr=="JUL"
replace month_old=8 if monthstr=="AUG"
replace month_old=9 if monthstr=="SEP"
replace month_old=10 if monthstr=="OCT"
replace month_old=11 if monthstr=="NOV"
replace month_old=12 if monthstr=="DEC"
drop if month<month_old&ref_year==`x'
}
drop month_old
gen visits_lasty=1
collapse (sum) visits_lasty, by()
save $dataout/visits_lasty, replace
restore

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