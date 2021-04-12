##-Set parameters
set trajName TRAJNAME
set C2psf TRAJPSF
set refpsf REFPSF
set refpdb REFPDB
set beg BEG
set skip SKIP
set end END
set memType MEMT
set outN OUTNAME
set cutOff CCOFF
##--------------------


##-Load reference C1 structure;& get the coordinates of reference atoms for distance calculation
mol load psf $refpsf pdb $refpdb
set C1ID [molinfo top get id]
set C1Resid [[atomselect $C1ID "all"] get resid]
#set C1Pos [[atomselect $C1ID "all"] get {x y z}]
##----------------------

##-Load C2 trajectories;& measure the number of frames
mol new $C2psf
mol addfile $trajName beg $beg step $skip end $end waitfor all
set C2ID [molinfo top get id]
set Nframes [expr {[molinfo $C2ID get numframes] - 1}]
set C2Resid [[atomselect $C2ID "all"] get resid]
##----------------------

##-Set atom selections; assume a ".contact." structure specified for contact measurements was loaded
if {[string equal $memType "PC_2QCR6"] || [string equal $memType "PC_0QCR6"] || [string equal $memType "PC_0.5QCR6"]} {
  set selC1s [list "segname c3m1" "segname c3m2" "segname c4m1" "segname c4m2" "segname qcm1" "segname qcm2" "resname POPC"]
} elseif {[string equal $memType "CL_2QCR6"] || [string equal $memType "CL_0QCR6"] || [string equal $memType "CL_0.5QCR6"] || [string equal $memType "CL_1QCR6"]} {
  set selC1s [list "segname c3m1" "segname c3m2" "segname c4m1" "segname c4m2" "segname qcm1" "segname qcm2" "resname POPC TOCL1" "resname POPC" "resname TOCL1"]
} else {
  puts "no such membrane type!"
}
set selC2s [list "protein"]
set C1Len [llength $selC1s]
set C2Len [llength $selC2s]
##----------------------

##-Set output files
set fileContactsNum $outN.ContactsNum.dat
set fileContactsList $outN.ContactsList.dat
set fileHHdist $outN.HHdist.dat
set foutCN [open $fileContactsNum w]
set foutCL [open $fileContactsList w]
#set foutHH [open $fileHHdist w]
##----------------------

##-Create headers
puts -nonewline $foutCN "(noh for all) C1-selections: "
puts -nonewline $foutCL "(noh for all) C1-selections: "
for {set i 0} {$i < $C1Len} {incr i} {
  puts -nonewline $foutCN "[lindex $selC1s $i];"
  puts -nonewline $foutCL "[lindex $selC1s $i];"
}
puts -nonewline $foutCN  "C2-selections: "
for {set i 0} {$i < $C2Len} {incr i} {
  puts -nonewline $foutCN "[lindex $selC2s $i];"
  puts -nonewline $foutCL "[lindex $selC2s $i];"
}
puts $foutCN ""
puts $foutCL ""
puts -nonewline $foutCN "Frame "
puts -nonewline $foutCL "Frame "
for {set i 0} {$i < $C1Len} {incr i} {
  for {set j 0} {$j < $C2Len} {incr j} {
    puts -nonewline $foutCN "ContactCopy ContactPairNum($i;$j) UniqueC1Contact($i;$j) UniqueC2Contact($i;$j); "
    puts -nonewline $foutCL "ContactPairC1Resid($i;$j) ContactPairC2IDResid($i;$j); "
  }
}
puts $foutCN ""
puts $foutCL ""
#puts $foutHH "Frame F-F-MINdist H-H-MINdist F-F(functional) H-H(functional)"

##-Loop over C2 trajectories
for {set l 0} {$l <= $Nframes} {incr l} {
  #set C2Pos [[atomselect $C2ID "all" frame $l] get {x y z}]
  puts -nonewline $foutCN "$l "
  puts -nonewline $foutCL "$l "
  #puts -nonewline $foutHH "$l "
  #set fe1 [atomselect $C1ID "name FE and ([lindex $selC1s 1])"]
  #set fe2 [atomselect $C2ID "name FE and ([lindex $selC2s 1])" frame $l]
  #set f1list [$fe1 get index]
  #set f2list [$fe2 get index]
  #set tempList ""
  #foreach indf1 $f1list {
  # foreach indf2 $f2list {
  #    set dist [vecdist [lindex $C1Pos $indf1] [lindex $C2Pos $indf2]]
  #    lappend tempList $dist
  #  }
  #}
  #set tempList [lsort -real $tempList]
  #set ffdist [lindex $tempList 0]
  #puts -nonewline $foutHH "$ffdist "

  #set he1 [atomselect $C1ID "noh and ([lindex $selC1s 1])"]
  #set he2 [atomselect $C2ID "noh and ([lindex $selC2s 1])" frame $l]
  #set h1list [$he1 get index]
  #set h2list [$he2 get index]
  #set tempList ""
  #foreach indh1 $h1list {
  # foreach indh2 $h2list {
  #    set dist [vecdist [lindex $C1Pos $indh1] [lindex $C2Pos $indh2]]
  #    lappend tempList $dist
  #  }
  #}
  #set tempList [lsort -real $tempList]
  #set hhdist [lindex $tempList 0]
  #puts -nonewline $foutHH "$hhdist "

  ##-Compute F-F & H-H distance only between hemes involved in cross-protein e- transport
  #set feFun [atomselect $C1ID "name FE and ([lindex $selC1s 2])"]
  #set fFlist [$feFun get index]
  #set tempList ""
  #foreach indf1 $fFlist {
  # foreach indf2 $f2list {
  #    set dist [vecdist [lindex $C1Pos $indf1] [lindex $C2Pos $indf2]]
  #    lappend tempList $dist
  #  }
  #}
  #set tempList [lsort -real $tempList]
  #set ffdist [lindex $tempList 0]
  #puts -nonewline $foutHH "$ffdist "

  #set heF [atomselect $C1ID "noh and ([lindex $selC1s 2])"]
  #set he2 [atomselect $C2ID "noh and ([lindex $selC2s 1])" frame $l]
  #set hFlist [$heF get index]
  #set h2list [$he2 get index]
  #set tempList ""
  #foreach indh1 $hFlist {
  # foreach indh2 $h2list {
  #    set dist [vecdist [lindex $C1Pos $indh1] [lindex $C2Pos $indh2]]
  #    lappend tempList $dist
  # }
  #}
  #set tempList [lsort -real $tempList]
  #set hhdist [lindex $tempList 0]
  #puts -nonewline $foutHH "$hhdist "

  ##-Measure contacts part
  for {set i 0} {$i < $C1Len} {incr i} {
    for {set j 0} {$j < $C2Len} {incr j} {
      set selC1 [atomselect $C1ID "noh and ([lindex $selC1s $i])"]
      set selC2 [atomselect $C2ID "noh and ([lindex $selC2s $j])" frame $l]
      set Clist [measure contacts $cutOff $selC1 $selC2]
      set C1list [lindex $Clist 0]
      set C2list [lindex $Clist 1]
      set CPnum [llength $C1list]
      set CP1num [llength [lsort -unique $C1list]]
      set CP2num [llength [lsort -unique $C2list]]
      if {$CPnum > 0} {
        set C1temp [atomselect $C1ID "index [lsort -unique $C1list]"]
        set CCopy [llength [lsort -unique [$C1temp get segname]]]
        #$C1temp delete
        #set tempList ""
        #foreach indA $C1list indB $C2list {
        #  set dist [vecdist [lindex $C1Pos $indA] [lindex $C2Pos $indB]]
        #  lappend tempList $dist
        #}
        #set tempList [lsort -real $tempList]
        #set avedist [expr ([join $tempList +])/[llength $tempList]]
        #set mindist [lindex $tempList 0]
      } else {
        set CCopy 0
        #set avedist 0
        #set mindist 0
      }
      #puts -nonewline $foutCN "$CCopy $CPnum $CP1num $CP2num $mindist $avedist; "
      puts -nonewline $foutCN "$CCopy $CPnum $CP1num $CP2num; "
      if {$CPnum > 0} {
        set tempList ""
        foreach indA $C1list indB $C2list {
          set resid1 [lindex $C1Resid $indA]
          set resid2 [lindex $C2Resid $indB]
          lappend tempList [list "$resid1 $resid2"]
        }
        set tempList [lsort -unique $tempList]
        set tempNum [llength $tempList]
        set C1conResid ""
        set C2conResid ""
        for {set rd 0} {$rd < $tempNum} {incr rd} {
          lappend C1conResid [lindex [lindex [lindex $tempList $rd] 0] 0]
          lappend C2conResid [lindex [lindex [lindex $tempList $rd] 0] 1]
        }
      } else {
        set tempList [list 0 0]
        set C1conResid 0
        set C2conResid 0
      }
      puts -nonewline $foutCL "{$C1conResid} {$C2conResid}; "
    }
  }
  puts $foutCN ""
  puts $foutCL ""
  #puts $foutHH ""
}

close $foutCN
close $foutCL
#close $foutHH
