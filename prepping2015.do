// Author: Igor Francetic
// Date: 19/02/2026
// This do-file creates the long-format treatment data for 2015, called by "prepping.do"

clear all

// Import patients file 2015
clear all
import delimited "$datain\2015\HOA_TREATMENT_GEO_COMP_2015.csv"
egen finregime=group(law_content_cd)
* Save clean dataset and filter ED attendances
drop if is_vcode_aleat==0
save "$dataout\2015_patients", replace

// Import (within ED) treatments
clear all
forvalues i=1/6 {
clear all
import delimited "$datain\2015\HOA_SERVICE_GEO_COMP_`i'_2015"
gen edcode=0
replace edcode=1 if inlist(service_code, "35.0610", "35.05" /*, "00.2510", "00.2520", "00.2540", "00.2505" */)
bysort treatment_id: egen edatt=max(edcode)
keep if edatt==1
compress
save "$dataout\2015_treat_`i'", replace
}


//Append all together and add tariff type flags
clear all
use "$dataout\2015_treat_6", clear
append using "$dataout\2015_treat_5"
append using "$dataout\2015_treat_4"
append using "$dataout\2015_treat_3"
append using "$dataout\2015_treat_2"
append using "$dataout\2015_treat_1"

rename service_tar_cd tariftype
replace tariftype="999" if tariftype=="MAT"|tariftype=="H03"|tariftype=="H04"|tariftype=="E02"|tariftype=="FPP"|tariftype=="H03"|tariftype=="S15"|tariftype=="W00"|tariftype=="TAR"
merge m:1 tariftype using "$dataout\tariftypes", keepusing(tarifdes)
drop if _merge==2
drop _merge
destring tariftype, replace
replace tarifdes="Missing" if tariftype==999
replace tariftype=999 if inlist(tariftype, 2, 101, 302, 316, 450, 699, 998)
drop if tariftype==90|tariftype==91
drop if service_qty<0|service_amount<0

// Generate dummies for types of service
gen serv_outpat=0
replace serv_outpat=1 if inlist(tariftype, 1,7, 532, 534, 551, 552, 590, 595, 940)
gen serv_inpat=0
replace serv_inpat=1 if inlist(tariftype, 10, 12, 501, 502, 503, 535, 800, 910, 930, 960)
gen serv_analys=0
replace serv_analys=1 if inlist(tariftype, 317, 318)
gen serv_dental=0
replace serv_dental=1 if inlist(tariftype, 222,223,320,321,322,323)
gen serv_physicalther=0
replace serv_physicalther=1 if inlist(tariftype, 21,22,311,312,324,325,338,341,353,424,353,354,355,356)
gen serv_mentalhealth=0
replace serv_mentalhealth=1 if inlist(tariftype, 30, 31, 330, 340, 352, 581, 582, 915)
gen serv_protsupp=0
replace serv_protsupp=1 if inlist(tariftype, 329, 331, 337 907, 908, 909, 910, 914, 925)
gen serv_otherther=0
replace serv_otherther=1 if inlist(tariftype, 50, 280, 290,326, 327, 328, 332, 334, 350, 351, 354, 401, 406, 407, 408, 500, 510, 511, 512, 513, 514, 515, 516, 965, 966, 967, 970)
gen serv_ambul=0
replace serv_ambul=1 if inlist(tariftype, 580, 583, 584)
gen serv_medicines=0
replace serv_medicines=1 if inlist(tariftype, 400, 402, 403, 404, 405, 451, 570, 571)
gen serv_homesocial=0
replace serv_homesocial=1 if inlist(tariftype, 504, 533, 904, 923, 963, 964, 971)
gen serv_matern=0
replace serv_matern=1 if inlist(tariftype, 550, 551, 552)
gen serv_intcare=0
replace serv_intcare=1 if inlist(tariftype, 505)
gen serv_supplies=0
replace serv_supplies=1 if inlist(tariftype, 410, 452, 453, 454, 980)

// Coding main Tarmed chapter
gen tarmed4=substr(service_code,1,5) if tariftype==1
gen tarmed2=substr(service_code,1,2) if tariftype==1
gen det_tariff=.
replace det_tariff=0 if tarmed2=="00"
replace det_tariff=1 if tarmed2=="01"
replace det_tariff=2 if tarmed2=="02"
replace det_tariff=3 if tarmed2=="03"
replace det_tariff=4 if tarmed2=="04"
replace det_tariff=5 if tarmed2=="05"
replace det_tariff=6 if tarmed2=="06"
replace det_tariff=7 if inlist(tarmed2, "07", "08", "09", "10", "11", "12", "13", "14")
replace det_tariff=8 if tarmed2=="15"
replace det_tariff=9 if tarmed2=="16"
replace det_tariff=10 if tarmed2=="17"
replace det_tariff=11 if tarmed2=="18"
replace det_tariff=12 if tarmed2=="19"
replace det_tariff=13 if tarmed2=="20"
replace det_tariff=14 if tarmed2=="21"
replace det_tariff=15 if tarmed2=="22"
replace det_tariff=16 if tarmed2=="23"
replace det_tariff=17 if tarmed2=="24"
replace det_tariff=18 if tarmed2=="26"
replace det_tariff=19 if tarmed2=="27"
replace det_tariff=20 if tarmed2=="28"|tarmed2=="29"
replace det_tariff=21 if tarmed2=="31"|tarmed2=="32"
replace det_tariff=22 if tarmed2=="33"
replace det_tariff=23 if tarmed2=="34"
replace det_tariff=24 if inlist(tarmed4, "35.01", "35.03", "35.04")
replace det_tariff=25 if tarmed2=="39"
replace det_tariff=30 if tariftype==317
replace det_tariff=40 if tariftype==402
replace det_tariff=50 if edcode==1
replace det_tariff=90 if missing(det_tariff)

label define tarlabs 	0 "Baseline tariffs" ///
						1 "Bendages" ///
						2 "Psychiatry" ///
						3 "Children" ///
						4 "Skin" ///
						5 "Neurology" ///
						6 "Spine" ///
						7 "Head and neck" ///
						8 "Diagnostics: Lungs" ///
						9 "Surgery: Torax" ///
						10 "Diagnostics: Heart" ///
						11 "Surgery: Heart" ///
						12 "Diagnostics: GI" ///
						13 "Surgery: GI" ///
						14 "Diagnostics: Urinary tract" ///
						15 "Diagnostics: Women's genitals" ///
						16 "Diagnostics: Breasts" ///
						17 "Diagnostics: Muskoloskeletal system" ///
						18 "Diagnostics: Lymph nodes" ///
						19 "Organ transplant" ///
						20 "Anesthesia and pain" ///
						21 "Nuclear medicine and radiotherapy" ///
						22 "Dialysis" ///
						23 "Intensive care" ///
						24 "Day hospital" /// 
						25 "Diagnostic imaging" ///
						30 "Lab analyses" ///
						40 "Medical supplies" ///
						50 "ED attendance fee" ///
						90 "Other treatments pooled"
label values det_tariff tarlabs
label variable det_tariff "Relevant tariff"
merge m:1 treatment_id using "$dataout/2015_patients"
drop if _merge==2
drop _merge

save "$dataout/2015_long", replace
forvalues i=1/6{
erase $dataout\2015_treat_`i'.dta
}

