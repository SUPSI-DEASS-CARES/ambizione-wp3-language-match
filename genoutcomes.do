// Author: Igor Francetic
// Date: 19/02/2026
// This do-file is called by "prepping.do"

// Construct outcome variables
gen temp=(visit_phase=="Anamnesis")
gen anamnesistime=flag*temp
gen cost1=temp*service_amount
drop temp
gen temp=(visit_phase=="Diagnosis")
gen diagnosistime=flag*temp
gen cost2=temp*service_amount
drop temp
gen diagimaging=(visit_phase=="Diagnostic imaging")
gen cost3=diagimaging*service_amount
gen costs=cost1+cost2+cost3
drop cost1 cost2 cost3