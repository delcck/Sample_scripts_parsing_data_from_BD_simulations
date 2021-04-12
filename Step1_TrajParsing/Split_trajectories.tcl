## Import trajectory name, input directory, and output directory
set prefix $argv
source Split_trajectories_pros.tcl
set trajN [lindex $prefix 0]
set InD [lindex $prefix 1]
set OutD [lindex $prefix 2]
set TrajLength [lindex $prefix 3]
DataOutput $trajN $InD $OutD $TrajLength
