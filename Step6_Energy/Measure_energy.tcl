## Setting parameters
set prefix TRAJNAME
set psfN PSFN
set beg BEG
set skip SKIP
set end END
set memType MEMT
set outN OUTNAME
set swNum SWNUM
set cutNum CUTNUM
set temperature TEMP
set tempFName REDOXD
set par1 "/Scr/delcck/cytc-ARBD/MD_Simulation/parameters/par_all36_prot.prm"
set par2 "/Scr/delcck/cytc-ARBD/MD_Simulation/parameters/par_all36_lipid.prm"
set par3 "/Scr/delcck/cytc-ARBD/MD_Simulation/parameters/par_all36_carb.prm"
set par4 "/Scr/delcck/cytc-ARBD/MD_Simulation/parameters/par_all36_na.prm"
set par5 "/Scr/delcck/cytc-ARBD/MD_Simulation/parameters/par_all36_cgenff.prm"
set par6 "/Scr/delcck/cytc-ARBD/MD_Simulation/parameters/SI2_CHARMM_parameter_fileORIG.prm"
set par7 "/Scr/delcck/cytc-ARBD/MD_Simulation/parameters/SI2_CHARMM_parameter_file.prm"
set par8 "/Scr/delcck/cytc-ARBD/MD_Simulation/parameters/pho.prm"
set par9 "/Scr/delcck/cytc-ARBD/MD_Simulation/parameters/cla.prm"
set par10 "/Scr/delcck/cytc-ARBD/MD_Simulation/parameters/fake-tmp.prm"
set par11 "/Scr/delcck/cytc-ARBD/MD_Simulation/parameters/pl9.prm"

## Loading trajectory
mol new $psfN.psf
mol addfile $prefix.dcd waitfor all
set trajID [molinfo top get id]

## Setting atom selections
set selC2s [list "segname PROV"]
if {[string equal $memType "PC_2QCR6"] || [string equal $memType "PC_0QCR6"] || [string equal $memType "PC_0.5QCR6"]} {
  #set selC1s [list "segname c3m1" "segname c3m2" "segname c4m1" "segname c4m2" "segname qcm1" "segname qcm2" "resname POPC"]
  #All segname are not availabble due to re-naming upon structure merging
  set selC1s [list "protein and not segname PROV" "resname POPC"]
} elseif {[string equal $memType "CL_2QCR6"] || [string equal $memType "CL_0QCR6"] || [string equal $memType "CL_0.5QCR6"] || [string equal $memType "CL_1QCR6"]} {
  #set selC1s [list "segname c3m1" "segname c3m2" "segname c4m1" "segname c4m2" "segname qcm1" "segname qcm2" "resname POPC"]
  #All segname are not availabble due to re-naming upon structure merging
  set selC1s [list "protein and not segname PROV" "resname POPC TOCL1"]
} else {
  puts "no such membrane type!"
}
set C1Len [llength $selC1s]
set C2Len [llength $selC2s]

## Compute energy for each atom selection
package require namdenergy
for {set i 0} {$i < $C1Len} {incr i} {
  for {set j 0} {$j < $C2Len} {incr j} {
    set outFName $outN.Energy.$i.$j.dat
    set selC1 [atomselect $trajID "[lindex $selC1s $i]"]
    set selC2 [atomselect $trajID "[lindex $selC2s $j]"]
    namdenergy -vdw -elec -nonb -sel $selC1 $selC2 -ofile $outFName -switch $swNum -cutoff $cutNum -par $par1 -par $par2 -par $par3 -par $par4 -par $par5 -par $par6 -par $par7 -par $par8 -par $par9 -par $par10 -par $par11 -tempname temp.$tempFName.$i.$j
  }
}
