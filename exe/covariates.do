// Author: Igor Francetic
// Date: 19/02/2026
// This do-file is called by "prepping.do"

// Create covariates

// World region
rename natio_reg_cd nationality
replace nationality="1" if nationality=="CHE"
replace nationality="2" if nationality=="DEU"
replace nationality="3" if nationality=="FRA"
replace nationality="4" if nationality=="ITA"
replace nationality="5" if nationality=="LIE"
replace nationality="6" if nationality=="AUT"
destring nationality, replace
replace nationality=99 if nationality<0

// Prepare groups of nations
gen grnation=nationality if nationality<5&nationality!=.
replace grnation=5 if nationality==5|nationality==6
replace grnation=6 if nationality==11
replace grnation=7 if nationality==12
replace grnation=8 if nationality==13
replace grnation=9 if nationality==21
replace grnation=10 if nationality==22
replace grnation=11 if nationality==23
replace grnation=12 if nationality==31|nationality==32
replace grnation=13 if nationality==41|nationality==42
replace grnation=14 if nationality==51|nationality==52|nationality==61|nationality==62
replace grnation=15 if nationality==63
replace grnation=16 if nationality==71|nationality==72
replace grnation=17 if nationality==81|nationality==9
replace grnation=18 if nationality==99|missing(nationality)

// Referral source
rename sect_ttl_rfr_cd refsource

// Canton
rename kanton_patient pat_canton 
replace pat_canton="" if pat_canton=="-2"|pat_canton=="-4"
replace pat_canton="INT" if pat_canton=="-3"
rename bur_kanton hosp_canton

// Prepare some covariates
gen log_total=ln(service_amount)
gen monthstr=substr(treat_dt_beg, 1, 3)
gen month=.
replace month=1 if monthstr=="JAN"
replace month=2 if monthstr=="FEB"
replace month=3 if monthstr=="MAR"
replace month=4 if monthstr=="APR"
replace month=5 if monthstr=="MAY"
replace month=6 if monthstr=="JUN"
replace month=7 if monthstr=="JUL"
replace month=8 if monthstr=="AUG"
replace month=9 if monthstr=="SEP"
replace month=10 if monthstr=="OCT"
replace month=11 if monthstr=="NOV"
replace month=12 if monthstr=="DEC"

* Drop useless
drop law_content_cd