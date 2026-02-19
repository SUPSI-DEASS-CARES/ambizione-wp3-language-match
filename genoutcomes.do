// Author: Igor Francetic
// Date: 22/01/2026
// This do-file is called by "prepping.do"

// Construct outcome variables
gen temp=(visit_phase=="Anamnesis")
gen anamnesistime=flag*temp
drop temp
gen temp=(visit_phase=="Diagnosis")
gen diagnosistime=flag*temp
drop temp
gen diagimaging=(visit_phase=="Diagnostic imaging")

// Define outcomes for analysis
gen time_basic=ln(anamnesistime)
gen any_diagact=(diagnosistime>0)
gen time_diagact=ln(diagnosistime)
gen any_diagtest=(diagimaging>0)
gen count_diagtest=diagimaging if diagimaging>0