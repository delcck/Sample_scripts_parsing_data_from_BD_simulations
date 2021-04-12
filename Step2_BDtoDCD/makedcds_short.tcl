# set smooth 1

#proc makeDcdARBD {molID trajName C2Name outputDirName outtrajName} {
	set prefix TRAJNAME
	set outputtraj OUTPUTTRAJ
	set STRindir STRINDIR
	set psf C2NAME.psf
	set pdb C2NAME.pdb
	source arbd-vis.procs.tcl

	set skip SKIP
	set beg BEG
	set end END

	set files [sortFileGlob $prefix.rb-traj]
	array set trans [parseRigidBodyTrajectoryFiles $files $skip $beg $end]
	set keys [array names trans]
	set numFrames [llength $trans([lindex $keys 0])]

	## set up molecule
	set ID [mol new $STRindir/$psf]
	mol addfile $STRindir/$pdb
	while {[molinfo $ID get numframes] < $numFrames} {
    		animate dup $ID
	}

	set sel [atomselect $ID all]
	set initialCoords [$sel get {x y z}]; list

	#set dcds $outputDirName
	#file mkdir dcds

	foreach key $keys {

    		## optionally smooth
    		if [info exists smooth] {
			if {$smooth > 1} {
	    			set trans($key) [smooth4by4RotationMatrices 2 $trans($key)]
			}
    		}

    		## move selection
    		for {set f 0} {$f < $numFrames} {incr f} {
			$sel frame $f
			$sel set {x y z} $initialCoords
			$sel move [lindex $trans($key) $f]
    		}
    		regexp {.*#([0-9]+)} $key --> num
    		#animate write dcd [format "$outputtraj.%03d.dcd" $num] waitfor all
				animate write dcd [format "$outputtraj.dcd" $num] waitfor all
	}
#}
