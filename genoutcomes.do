// Author: Igor Francetic
// Date: 19/02/2026
// This do-file is called by "prepping.do"

// Construct outcome variables
gen temp=(visit_phase=="Anamnesis")
gen anamnesistime=flag*temp
drop temp
gen temp=(visit_phase=="Diagnosis")
gen diagnosistime=flag*temp
drop temp
gen diagimaging=(visit_phase=="Diagnostic imaging")
