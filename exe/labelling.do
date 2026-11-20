// Author: Igor Francetic
// Date: 20/11/2026
// This do-file is called by "prepping.do"

// Labelling covariates and exposure
label define sexlab		1 "Male" 2 "Female"
label values gender_cd sexlab
label var gender_cd "Biological sex"
label var year "Year"

label define reflab		1 "Self-referral" ///
						2 "Emergency service" ///
						3 "Doctor/GP" ///
						4 "Other healthcare provider" ///
						5 "Social care service" ///
						6 "Justice authorities" ///
						7 "Hospital (internal referral)" ///
						8 "Other" ///
						9 "Missing"
label values refsource reflab 
label variable refsource "Referral source"

label define natlab		1 "Swiss" ///
						2 "Germany" ///
						3 "France" ///
						4 "Italy" ///
						5 "Liechtenstein" ///
						6 "Austria" ///
						11 "West Europe" ///
						12 "East Europe" ///
						13 "North Europe" ///
						21 "West and Central Africa" ///
						22 "East and South Africa" ///
						23 "North Africa" ///
						31 "Canada" ///
						32 "USA" ///
						41 "South America" ///
						42 "Central America and Caribbean" ///
						51 "China" ///
						52 "Japan" ///
						61 "Southeast Asia" ///
						62 "South Asia" ///
						63 "Middle-East" ///
						71 "Australia and New Zealand" ///
						72 "Oceania (islands)" ///
						81 "Russia and former URSS" ///
						9 "Other" ///
						99 "Missing"
label values nationality natlab
label variable nationality "Nationality group"

label define natgrlab	1 "Swiss" ///
						2 "Germany" ///
						3 "France" ///
						4 "Italy" ///
						5 "Austria & Liechtenstein" ///
						6 "West Europe" ///
						7 "East Europe" ///
						8 "North Europe" ///
						9 "West/Central Africa" ///
						10 "East/South Africa" ///
						11 "North Africa" ///
						12 "US and Canada" ///
						13 "Central & South America & Caribbean" ///
						14 "Asia (incl. China and Japan)" ///
						15 "Middle East" ///
						16 "Australia & Oceania" ///
						17 "Russia/former URSS and other" ///
						18 "Missing"
label values grnation natgrlab
label variable grnation "Nationality groups"

label define finlabs 	1 "Disability insurance" ///
						2 "Mandatory insurance" ///
						3 "Military insurance" ///
						4 "Privately paid" ///
						5 "Accident insurance" ///
						6 "Supplementary insurance" ///
						7 "Missing"
label values finregime finlabs
label variable finregime "Financing regime"

label define agelab	0 "Aged 0-4" ///
						5 "Aged 5-9" ///
						10 "Aged 10-14" ///
						15 "Aged 15-19" ///
						20 "Aged 20-24" ///
						25 "Aged 25-29" ///
						30 "Aged 30-34" ///
						35 "Aged 35-39" ///
						40 "Aged 40-44" ///
						45 "Aged 45-49" ///
						50 "Aged 50-54" ///
						55 "Aged 55-59" ///
						60 "Aged 60-64" ///
						65 "Aged 65-69" ///
						70 "Aged 70-74" ///
						75 "Aged 75-79" ///
						80 "Aged 80-84" ///
						85 "Aged 85-89" ///
						90 "Aged 90-94" ///
						95 "Aged 95+"
label values age_class agelab
label variable age_class "Age bin"
						
label var quintile_tertiary "MedStat tertiary educatiational attainment"
label define quintedu 1 "Quintile 1" 2 "Quintile 2" 3 "Quintile 3" 4 "Quintile 4" 5 "Quintile 5"
label values quintile_tertiary quintedu

label define prevlab 0 "0" 1 "1" 2 "2" 3 "3" 4 "4" 5 "5 or more"
label values visits_prior12 prevlab
label variable visits_prior12 "ED visits in the prev. 12 months"
label define binany 0 "No" 1 "Yes"
label values any_hosp12 binany
label variable any_hosp12 "Hospital stays in the prev. 12 months"

label var any_basic "Any time spent on basic consultations"
label values any_basic binany
label var anamnesistime "Time spent on basic consultations"
label var time_basic "(Log) Time spent on basic consultations"
label var diagnosistime "Time spent on diagnostic activity"
label var any_diagact "Any diagnostic activity"
label values any_diagact binany
label var time_diagact"(Log) Time spent on diagnostic activity"
label var any_diagtest "Any diagnostic imaging test"
label values any_diagtest binany
label var diagimaging  "Count of diagnostic imaging tests ordered"
label var count_diagtest "(Log) Count of diagnostic imaging tests ordered"
label var costs "Amount billed (in Swiss Francs)"
