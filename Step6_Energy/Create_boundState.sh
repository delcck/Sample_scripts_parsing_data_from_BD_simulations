Prefix="0QCR6_CL..15"

alias vmdd='vmd -dispdev text'

vmd < "$Prefix.SampleTraj_bound.tcl"
wait -n
vmd < "$Prefix.C3m1_bound.tcl"
vmd < "$Prefix.C3m2_bound.tcl"
vmd < "$Prefix.C4m1_bound.tcl"
vmd < "$Prefix.C4m2_bound.tcl"
vmd < "$Prefix.Qcm1_bound.tcl"
vmd < "$Prefix.Qcm2_bound.tcl"
vmd < "$Prefix.Membrane_bound.tcl"
