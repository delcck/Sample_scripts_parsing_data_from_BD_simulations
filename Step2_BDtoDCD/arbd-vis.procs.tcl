proc dcd {dcdGlob args} {
    set molid ""
    set defaults { {skip 1} {beg 0} {end 0 } }
    foreach {var val} [join $defaults] { set $var $val }
    foreach {var val} [join $args] { set $var $val }

    if { [string equal $molid top] || [string equal $molid ""] } { set molid [molinfo top] }

    set startFrames [molinfo $molid get numframes] ;# use this to return the number of frames loaded
    set framesLeft 1;

    foreach glob $dcdGlob {
        set dcds [sortFileGlob $glob]
        foreach dcd $dcds { ;# loop through dcds in dcdGlob
            if { $framesLeft == 0 } { break }
            if { ![file exists $dcd] } { continue }
            set dcdFrames [numframes $dcd]
            puts "reading $dcd ($dcdFrames)"

            ## set beg and end
            if { $beg > 0 } {
                set animateBeg $beg
            } else {
                set animateBeg 0
            }


            set animateEnd ""
            if { $dcdFrames > $end && $end > 0} {
                set animateEnd $end
                set framesLeft 0 ;# break if no frames left!
            }

            ## update beg & end
            set beg [expr {$beg - $dcdFrames}]
            set end [expr {$end - $dcdFrames}]

            if { $animateBeg >= $dcdFrames } { continue }
            set beg [expr {$skip-1-int(fmod( ($dcdFrames-$animateBeg),$skip ))}] ;# don't load dcds that are too smaller than skip

            ## do the loadin
            set animateBeg "beg $animateBeg"
            if {$animateEnd > 0} { set animateEnd "end $animateEnd" }
            # puts "animate read dcd $dcd skip $skip $animateBeg $animateEnd waitfor all $molid"
            uplevel "animate read dcd $dcd skip $skip $animateBeg $animateEnd waitfor all $molid"
        }
    }
    set finalFrames [molinfo $molid get numframes]
    expr { $finalFrames - $startFrames }
}
proc numframes { args } {
    set r 0
    foreach dcd $args {
        set n [exec catdcd -num $dcd | awk "/^Total frames:/ \{ print \$3 \}"]
        set r [expr {$r + $n}]
    }
    return $r
}
proc sortFileGlob {fileGlob} {
    set files [glob $fileGlob]

    set sortCmd {{f1 f2} {
        set l1 [string length $f1]
        set l2 [string length $f2]
        set r [expr {($l1 > $l2) - ($l1 < $l2)}]
        if {$r == 0} { set r [string compare $f1 $f2] }
        return $r
    }}

    set sortCmd "apply {$sortCmd}"
    lsort -command $sortCmd $files
}
proc loadTrajectory {files {attachID top} {skip 1} {beg 0} {end -1}} {
    variable trans
    variable trans_orig
    variable trans_inv
    variable molToKey
    variable lastFrame
    variable rigidBodyIDs
    set rigidBodyIDs ""

    if { [string equal $attachID top] } {
	set attachID [molinfo top]
    }

    array set trans [parseRigidBodyTrajectoryFiles $files $skip $beg $end]
    set keys [array names trans]
    set rbFrames [llength $trans([lindex $keys 0])]
    set numframes [molinfo $attachID get numframes]

    if { $rbFrames < $numframes } {
	# error "Read $rbFrames rigid body frames < $numframes all-atom frames"
	puts "WARNING: Read $rbFrames rigid body frames < $numframes all-atom frames; something isn't right"
    }
    while { $rbFrames < $numframes } {
	foreach key [array names trans] {
	    lappend trans($key) [lindex $trans($key) end]
	}
	incr rbFrames
    }

    if { $rbFrames < $numframes } {
	error "Read $rbFrames rigid body frames < $numframes all-atom frames"
    }

    array set trans_orig [array get trans]
    calcTransInv

    set topID [molinfo top]
    if { [catch {
	set lastFrame $::vmd_frame($attachID)
	foreach key [array names trans] {
	    ## load ssb
	    set ID [mol new cytc2.psf]; mol addfile cytc2.pdb
	    molinfo $ID set {a b c} [molinfo $attachID get {a b c}]

	    lappend rigidBodyIDs $ID
	    set molToKey($ID) $key
	    [atomselect $ID all] move [lindex $trans($key) $lastFrame]
	}

	variable ::vmd_frame
	foreach elem [trace info variable ::vmd_frame($attachID)] {
	    foreach {opList cmd} $elem {
		trace remove variable ::vmd_frame($attachID) $opList $cmd
	    }
	}
	trace variable ::vmd_frame($attachID) w frameChange
    }]} {
	puts "WARNING: failed to set trace on rigidBody positions"
    }
    mol top $topID
    return $rigidBodyIDs
}

proc loadTrajectoryRbFrame {files {attachID top} {skip 1} {beg 0} {end -1} } {
    variable trans
    variable trans_orig
    variable trans_inv
    variable molToKey
    variable lastFrame
    variable rigidBodyIDs
    variable centerRbID
    set rigidBodyIDs ""

    if { [string equal $attachID top] } {
	set attachID [molinfo top]
    }

    array set trans [parseRigidBodyTrajectoryFiles $files $skip $beg $end]
    # array set trans [parseRigidBodyTrajectoryFiles $files ]
    set keys [array names trans]
    set rbFrames [llength $trans([lindex $keys 0])]
    set numframes [molinfo $attachID get numframes]
    if { $rbFrames < $numframes } {
	error "Read $rbFrames rigid body frames < $numframes all-atom frames"
    }

    array set trans_orig [array get trans]
    calcTransInv

    set topID [molinfo top]
    if { [catch {
	set lastFrame $::vmd_frame($attachID)
	foreach key [array names trans] {
	    ## load ssb
	    set ID [mol new 2tra.aligned.pdb]
	    # mol addfile ssb.pdb
	    molinfo $ID set {a b c} [molinfo $attachID get {a b c}]

	    lappend rigidBodyIDs $ID
	    set molToKey($ID) $key
	    # [atomselect $ID all] move [lindex $trans($key) $lastFrame]
	}

	## rb frame init
	if { ! [info exists centerRbID] } { set centerRbID [lindex $rigidBodyIDs 0] }
	# set key $molToKey($centerRbID);
	# set m [lindex $trans_inv($key) $lastFrame]
	# foreach tID [molinfo list] {
	#    [atomselect $tID all] move $m
	# }

	if { [catch { ## do transform for frame ; TODO undo and redo with smoothRot call
	    set rbID $centerRbID
	    set key $molToKey($rbID)
	    foreach tID [molinfo list] {
		if { [molinfo $tID get active] && [molinfo $tID get numframes] > 1 } {
		    set sel [atomselect $tID all]
		    frameLoop frame molid $tID {
			$sel frame $frame
			$sel move [lindex $trans_inv($key) $frame]
		    }
		}
	    }
	}]} { puts "WARNING: failed to initialize to rigidBody" }


	variable ::vmd_frame
	foreach elem [trace info variable ::vmd_frame($attachID)] {
	    foreach {opList cmd} $elem {
		trace remove variable ::vmd_frame($attachID) $opList $cmd
	    }
	}
	# trace variable ::vmd_frame($attachID) w frameChange
	trace variable ::vmd_frame($attachID) w frameChangeRbFrame
    }]} {
	puts "WARNING: failed to set trace on rigidBody positions"
    }
    mol top $topID
}

proc ::frameChangeCallback {frame} {}
proc frameChange {varname ID rw} {
    variable rigidBodyIDs
    variable trans
    variable trans_inv
    variable molToKey
    variable lastFrame
    set frame $::vmd_frame($ID)
    if { [catch {
	foreach rbID $rigidBodyIDs {
	    set key $molToKey($rbID)
	    set sel [atomselect $rbID all]
	    $sel move [lindex $trans_inv($key) $lastFrame]
	    $sel move [lindex $trans($key) $frame]
	}
    }]} {
	puts "WARNING: failed to update rigidBody positions"
    }
    catch {::frameChangeCallback $frame}
    set lastFrame $frame
}

proc frameChangeRbFrame {varname ID rw} {
    variable rigidBodyIDs
    variable trans
    variable trans_inv
    variable molToKey
    variable lastFrame
    variable centerRbID


    set frame $::vmd_frame($ID)

    if { [catch { ## undo transform to all RBs for last frame
    	set rbID $centerRbID
    	set key $molToKey($rbID)
    	foreach tID $rigidBodyIDs {
    	    set sel [atomselect $tID all]
	    $sel move [lindex $trans($key) $lastFrame]
    	}
    }]} {
    	puts "WARNING: failed to update rigidBody positions"
    }


    if { [catch {
	foreach rbID $rigidBodyIDs {
	    set key $molToKey($rbID)
	    set sel [atomselect $rbID all]
	    # $sel move [lindex $trans_inv($key) $lastFrame]
	    # $sel move [lindex $trans($key) $frame]
	    $sel move [transmult [lindex $trans($key) $frame] [lindex $trans_inv($key) $lastFrame]]
	}
    }]} {
	puts "WARNING: failed to update rigidBody positions"
    }
    if { [catch { ## do global transform for frame
	set rbID $centerRbID
	set key $molToKey($rbID)
	foreach tID $rigidBodyIDs {
	    set sel [atomselect $tID all]
	    $sel move [lindex $trans_inv($key) $frame]
	}
    }]} { puts "WARNING: failed to update rigidBody positions" }
    set lastFrame $frame
}

## support
proc parseRigidBodyTrajectoryFiles {files {skip 1} {beg 0} {end -1}} {
    set file [lindex $files 0]
    set files [lrange $files 1 end]


    # set counter [expr $skip-1]
    set counter 0
    lassign [parseRigidBodyTrajectory $file $skip $counter $beg $end] counter tmp
    # puts "tmp: $tmp"
    # puts "tmp has [llength $tmp] entries"
    # puts "tmp has [llength [join $tmp]] entries"
    array set trans $tmp
    set keys [array names trans]

    foreach file $files {
	lassign [parseRigidBodyTrajectory $file $skip $counter $beg $end] counter tmp
	array set newTrans $tmp
	if { [lsort $keys] != [lsort [array names newTrans]] } {
	    puts stderr "file $file does not share the same rigid bodies"
	    puts stderr "('[lsort $keys]' != '[lsort [array names newTrans]]')"
	    exit 1
	}
	foreach key $keys {
	    set trans($key) [join "{$trans($key)} {$newTrans($key)}"]
	}
    }
    return [array get trans]
}

proc parseRigidBodyTrajectory {file {skip 1} {counter 0} {beg 0} {end -1}} {
    ## parse and set transformation matrix timeseries

    array set trans ""
    array set keyCounter ""

    set rbCounter 0

    set ch [open $file]
    while { [gets $ch line] > 0 } {
	## ignore header
	if { [regexp {^\W*#} $line] } {
	    continue
	}
	# 	lassign [lindex $line 0] currentStep
	lassign [lindex $line 1] key

	if { ! [info exists trans($key)] } {
	    if {$rbCounter > 100} { continue }
	    set trans($key) ""
	    # incr rbCounter
	}
	if { ! [info exists keyCounter($key)] } {
	    set keyCounter($key) $counter
	} else {
	    incr keyCounter($key)
	}
	if { fmod($keyCounter($key),$skip) > 0.1 || $keyCounter($key) < $beg } { continue }

	if { $end >= 0 && $keyCounter($key) > $end + 2*$skip } { break } ;# break when you are well past $end
	if { $end >= 0 && $keyCounter($key) > $end } { continue } ;# not break in case there are multiple RBs
	set m ""
	lappend m [join "[lrange $line 5 7] 0"]
	lappend m [join "[lrange $line 8 10] 0"]
	lappend m [join "[lrange $line 11 13] 0"]
	lappend m {0 0 0 1}
	# set m [transmult [transoffset [lrange $line 2 4]] [measure inverse $m]]
	set m [transmult [transoffset [lrange $line 2 4]] $m]
	lappend trans($key) "$m"
	# puts "Added to trans($key); length = [llength $trans($key)]"
    }
    close $ch
    # puts "trans(ssb1): $trans(ssb1)"
    # puts "array get trans: [array get trans]"
    return "[lindex [array get keyCounter] 1] {[array get trans]}"
}


## smoothing
proc matrixToQuaternion {m} {
    ## http://en.wikipedia.org/wiki/Rotation_formalisms_in_three_dimensions#Rotation_matrix_.E2.86.94_quaternion
    lassign [lindex $m 0] Axx Axy Axz x1
    lassign [lindex $m 1] Ayx Ayy Ayz x2
    lassign [lindex $m 2] Azx Azy Azz x3

    # set denominator1 [expr 0.5*sqrt(1+$Axx+$Ayy+$Azz )]
    set denominator1 [expr 1+$Axx+$Ayy+$Azz]
    set denominator1 [expr ($denominator1 < 0) ? 0 : $denominator1]
    set denominator1 [expr 0.5*sqrt($denominator1)]

    set denominator2 [expr 1+$Axx-$Ayy-$Azz]
    set denominator2 [expr ($denominator2 < 0) ? 0 : $denominator2]
    set denominator2 [expr 0.5*sqrt($denominator2)]

    # set denominator3 [expr 0.5*sqrt(1+$Axx+$Ayy+$Azz )]
    if {$denominator1 > $denominator2} {
	set q4 $denominator1
	set q1 [expr ($Azy-$Ayz)*0.25/$q4]
	set q2 [expr ($Axz-$Azx)*0.25/$q4]
	set q3 [expr ($Ayx-$Axy)*0.25/$q4]
    } else {
	set q1 $denominator2
	set q2 [expr ($Axy+$Ayx)*0.25/$q1]
	set q3 [expr ($Axz+$Azx)*0.25/$q1]
	set q4 [expr ($Azy-$Ayz)*0.25/$q1]
    }
    return "$q1 $q2 $q3 $q4"
}
proc quaternionToMatrix {quat} {
    ## http://en.wikipedia.org/wiki/Rotation_formalisms_in_three_dimensions#Rotation_matrix_.E2.86.94_quaternion
    lassign $quat q1 q2 q3 q4
    return [list
	    [list [expr 1-2*($q2*$q2 + $q3*$q3)] [expr 2*($q1*$q2 - $q3*$q4)] [expr 2*($q1*$q3 + $q2*$q4)]]
	    [list [expr 2*($q1*$q2 + $q3*$q4)] [expr 1-2*($q1*$q1 + $q3*$q3)] [expr 2*($q2*$q3 - $q1*$q4)]]
	    [list [expr 2*($q1*$q3 - $q2*$q4)] [expr 2*($q1*$q4 + $q2*$q3)] [expr 1-2*($q2*$q2 + $q1*$q1)]]
	   ]
}
proc quaternionAndTransToMatrix {q r} {
    ## http://en.wikipedia.org/wiki/Rotation_formalisms_in_three_dimensions#Rotation_matrix_.E2.86.94_quaternion
    lassign $r r1 r2 r3
    lassign $q q1 q2 q3 q4
    set m "{[expr 1-2*($q2*$q2 + $q3*$q3)] [expr 2*($q1*$q2 - $q3*$q4)] [expr 2*($q1*$q3 + $q2*$q4)] $r1}
	   {[expr 2*($q1*$q2 + $q3*$q4)] [expr 1-2*($q1*$q1 + $q3*$q3)] [expr 2*($q2*$q3 - $q1*$q4)] $r2}
	   {[expr 2*($q1*$q3 - $q2*$q4)] [expr 2*($q1*$q4 + $q2*$q3)] [expr 1-2*($q2*$q2 + $q1*$q1)] $r3}
	   {0 0 0 1}"
    return $m
}

proc smoothRot {frames} {
    variable rigidBodyIDs
    variable trans_orig
    variable trans
    variable trans_inv
    variable molToKey
    variable lastFrame
    variable centerRbID

    if { [catch {
	foreach rbID $rigidBodyIDs {
	    set key $molToKey($rbID)
	    set sel [atomselect $rbID all]
	    if { ! [info exists centerRbID] || $rbID != $centerRbID } {
		$sel move [lindex $trans_inv($key) $lastFrame]
	    }
	}

	## undo transform for inRbFrame
	if { [info exists centerRbID] } {
	    set rbID $centerRbID
	    set key $molToKey($rbID)
	    foreach tID [molinfo list] {
		if { [molinfo $tID get active] && [molinfo $tID get numframes] > 1 } {
		    set sel [atomselect $tID all]
		    frameLoop frame molid $tID {
			$sel frame $frame
			# $sel move [lindex $trans($key) $frame]
		    }
		}
	    }
	}
    }]} {
	puts "WARNING: failed to put rigidBody at start"
    }

    if { [catch {
	foreach rbID $rigidBodyIDs {
	    set key $molToKey($rbID)
	    set trans($key) [smooth4by4RotationMatrices $frames $trans_orig($key)]
	}
    }]} {
	puts "WARNING: failed to smooth rigidBody positions"
    }
    calcTransInv


    if { [catch {
	foreach rbID $rigidBodyIDs {
	    set key $molToKey($rbID)
	    set sel [atomselect $rbID all]
	    if { ! [info exists centerRbID] || $rbID != $centerRbID } {
		$sel move [lindex $trans($key) $lastFrame]
	    }
	}

	## do transform for inRbFrame
	if { [info exists centerRbID] } {
	    set rbID $centerRbID
	    set key $molToKey($rbID)
	    foreach tID [molinfo list] {
		if { [molinfo $tID get active] && [molinfo $tID get numframes] > 1 } {
		    set sel [atomselect $tID all]
		    frameLoop frame molid $tID {
			$sel frame $frame
			# $sel move [lindex $trans_inv($key) $frame]
		    }
		}
	    }
	}
    }]} {
	puts "WARNING: failed to return rigidBody positions to frame $lastFrame"
    }
}
proc centerAll {ref} {
    variable rigidBodyIDs
    variable trans_orig
    variable trans
    variable trans_inv
    variable molToKey
    variable lastFrame

    set ID [$ref molid]
    frameLoop f molid $ID {
	$ref frame $f
	set v [vecinvert [measure center $ref]]
	puts "centerAll: frame $f: [vecinvert [measure center $ref]]"
    }
    if { [catch {
	foreach rbID $rigidBodyIDs {
	    set key $molToKey($rbID)
	    set sel [atomselect $rbID all]
	    $sel move [lindex $trans_inv($key) $lastFrame]
	}
    }]} {
	puts "WARNING: failed to put rigidBody at start"
    }

    frameLoop f molid $ID {
	$ref frame $f
	set v [vecinvert [measure center $ref]]
	puts "centerAll: frame $f: [vecinvert [measure center $ref]]"

	array set newTrans ""
	foreach rbID $rigidBodyIDs {
	    set key $molToKey($rbID)
	    # set m [transmult [transoffset [vecinvert [measure center $sel]]] [lindex $trans($key) $f]]
	    # puts "centerAll: frame $f: [vecinvert [measure center $sel]]"
	    set m [transmult [transoffset $v] [lindex $trans($key) $f]]
	    lappend newTrans($key) $m
	}
    }
    foreach rbID $rigidBodyIDs {
	set key $molToKey($rbID)
	set trans($key) $newTrans($key)
    }

    # if { [catch {
    # 	foreach rbID $rigidBodyIDs {
    # 	    set key $molToKey($rbID)
    # 	    set newTrans ""
    # 	    frameLoop f molid $ID {
    # 		$sel frame $f
    # 		# set m [transmult [transoffset [vecinvert [measure center $sel]]] [lindex $trans($key) $f]]
    # 		puts "centerAll: $ID frame $f: [vecinvert [measure center $sel]]"
    # 		set m [transmult [transoffset [vecinvert [measure center $sel]]] [lindex $trans($key) $f]]
    # 		lappend newTrans $m
    # 	    }
    # 	    set trans($key) $newTrans
    # 	}
    # }]} {
    # 	puts "WARNING: failed to smooth rigidBody positions"
    # }
    calcTransInv
    if { [catch {
	foreach rbID $rigidBodyIDs {
	    set key $molToKey($rbID)
	    set sel [atomselect $rbID all]
	    $sel move [lindex $trans($key) $lastFrame]
	}
    }]} {
	puts "WARNING: failed to return rigidBody positions to frame $lastFrame"
    }
    set all [atomselect $ID all]
    frameLoop f molid $ID {
	$ref frame $f
	$all frame $f
	$all moveby [vecinvert [measure center $ref]]
    }
}

proc smooth4by4RotationMatrices {frames rots} {
    set newRots ""
    set qs ""
    set rs ""

    foreach m $rots {
	lappend rs "[lindex $m 0 3] [lindex $m 1 3] [lindex $m 2 3]"
	lappend qs [matrixToQuaternion $m]
    }

    set numFrames [llength $rots]

    set rStack [lrange $rs 0 [expr $frames-1]]
    set qStack [lrange $qs 0 [expr $frames-1]]

    set newR  [eval "vecadd $rStack"]
    set newQ  [eval "vecadd $qStack"]

    for {set f 0} {$f < $numFrames} {incr f} {
	if {($f % 1000) == 0 || $f < 10 } { puts $f }
	## qstack (3 elements)
	## 1 2 3 4 ... 7 8 9

	## 1:   1 2
	## 2: 1 2 3
	## 3: 2 3 4
	## 8: 7 8 9
	## 9: 8 9

	if { $f > $frames } { ## drop excess frames from stack
	    # if {($f % 1000) == 0 || $f < 10 } {
	    # puts "newR: $newR"
	    # puts "newQ: $newQ"
	    # puts "rStack: $rStack"
	    # puts "qStack: $qStack"
	    # }

	    set newR [vecsub $newR [lindex $rStack 0]]
	    set rStack [lrange $rStack 1 end]

	    set newQ [vecsub $newQ [lindex $qStack 0]]
	    set qStack [lrange $qStack 1 end]
	}
	if { $f < $numFrames-$frames } { ## add to stack
	    set r [lindex $rs [expr $f+$frames]]
	    if { [catch {set newR [vecadd "$newR" "$r"]}] } {
		puts "failed adding r '$r'"
	    }
	    lappend rStack $r

	    set q [lindex $qs [expr $f+$frames]]
	    lappend qStack $q
	    if { [catch {set newQ [vecadd "$newQ" "$q"]}] } {
		puts "failed adding r '$r'"
	    }
	    # set newQ [vecadd $newQ $q]
	}

	if { [catch {
	    lappend newRots [quaternionAndTransToMatrix [vecnorm $newQ] [vecscale [expr 1.0/[llength $rStack]] $newR]]
	} ] } {
	    puts "fail adding $newQ $newR"
	}
    }
    return $newRots
}

proc calcTransInv {} {
    variable trans
    variable trans_inv
    array set trans_inv {}
    foreach key [array names trans] {
	set trans_inv($key) ""
	foreach m $trans($key) {
	    if { [catch {lappend trans_inv($key) [measure inverse $m]}] } {
		error "could not find inverse matrix of '$m'"
	    }
	}
    }
}
