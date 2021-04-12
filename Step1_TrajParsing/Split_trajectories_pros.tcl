#Task: read in rb-traj to generate files for individual replicas
#Pre1: procedure for calculating the total number of frame
proc framesInDcds {dcds} {
    set r 0
    foreach dcd $dcds {
	set n [exec catdcd -num $dcd | awk "/^Total frames:/ \{ print \$3 \}"]
	set r [expr {$r + $n}]
    }
    return $r
}

#Pre2: determine the number of particles
proc particleInTraj {trajs} {
	foreach traj $trajs {
		set fin [open $traj r]
		gets $fin line
		gets $fin line
		set count 0
		gets $fin line
		if { [llength $line] == 0} { continue } else {
			set refN [lindex $line 1]
			set count [expr $count + 1]
			gets $fin line
			if { [llength $line] > 0 } {
				set compN [lindex $line 1]
				while { ![string equal $compN $refN] } {
					set count [expr $count + 1]
					gets $fin line
					if { [llength $line] > 0 } {
						set compN [lindex $line 1]
					} else {set compN $refN}
				}
			}
		}
	}
	return $count
}

#Step1: read in trajectory file
proc DataOutput {trajN InD OutD trajL} {
	#set suffixA .0.dcd
	set suffixB .rb-traj
	#set dcdN $InD/$trajN$suffixA
	set trajName $InD/$trajN$suffixB
	set frameNUM $trajL
	set molNUM [particleInTraj $trajName]
	puts "loading: $trajName"
	puts stdout "molecule number = $molNUM"
	set totalLine [expr $frameNUM*$molNUM + 2]
	puts stdout "total number of frames = $frameNUM"
	puts stdout "output to: $OutD"
	puts stdout "Splitting trajectories….."
	for {set i 1} {$i <= $molNUM} {incr i} {
		set fin [open $trajName r]
		set outFName $OutD/$trajN.$i$suffixB
		set fout [open $outFName w]

		set count 1
		while { $count <= 2 } {
			gets $fin line
			puts $fout $line
			set count [expr $count + 1]
		}
#read shift
		for {set j 1} {$j <= [expr $i - 1]} {incr j} {
			gets $fin line
		}
		set count [expr $count + $i - 1]
#read
		while {$count <= $totalLine} {
			gets $fin line
			if { [llength $line] == 0 } { break }
			puts $fout $line
			set count [expr $count + 1]
			for {set j 0} {$j < [expr $molNUM - 1]} {incr j} {
				gets $fin line
				if { [llength $line] == 0 } { break }
				set count [expr $count + 1]
			}
		}
		close $fout
		close $fin
	}
	puts "done"
}
