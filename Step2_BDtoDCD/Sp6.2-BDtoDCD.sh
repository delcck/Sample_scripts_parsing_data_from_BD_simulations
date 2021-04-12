#! /bin/bash -x

## stop on errors
set -e
shopt -s expand_aliases
alias vmdd='vmd -dispdev text'

##Task: convert parsed BD trajectories in each restart directory to dcds for further MD reconstruction
## Goal: desposit BD-generated MD trajectories of cyt. C to separate directories labelled by the corresponding
## (i) Ion concentration; (ii) Number of restarts in the overall BD trajectory
## The calculation requires sourcing "makedcds_short.tcl" and "arbd-vis.procs.tcl". [BD simulation at 310k]
## Here, we assume the working trajectories are complete!!

##Variables;  Ion concentration/Vdw Scaling
ScalingList="1"
concList=".15"

#Variables;
#prefixesC1= background structure
prefixesC1="Mega_2QCR6"
#prefixesC2= diffusing particle
prefixesC2="cytC_pro"

##Variables; Number of trajectory index & &restart & system label [which is system dependent]
Numparticle=20
begparticle=1
stepparticle=1
sysName="CL_2QCR6"
prefixRestart="sp1."
begRestart=1
endRestart=6
stepRestart=1
frameOutputFrequency=1000
repeatStart=1
repeatEnd=16
Drepeat=1 #step of increment

##Variables for the output dcds [in MD form]
skip=100
beg=0
end=-1

##Variables; directories
dirLocalBD="/Scr/delcck/Megacomplex/Jacob/ProductionRun/$sysName"
dirOut="/Scr/delcck/Megacomplex/Jacob/Analysis/$sysName"
##Structure directory
STRindir="/Scr/delcck/Megacomplex/Jacob/Structure/cytC"
dirtrajOut="Combine"

##Scripts to be sourced
nameScript="makedcds_short.tcl"
tempScript="makedcds_short.temp.tcl"
dirScript="/Scr/delcck/Megacomplex/Jacob/Analysis"

for prefixC1 in $prefixesC1; do
	for prefixC2 in $prefixesC2; do
    for ScaleF in $ScalingList; do
	     for conc in $concList; do
         mkdir -p "$dirOut/$prefixC1$prefixC2.$conc"
         nameC2="$prefixC2.aligned"
         restartS=$begRestart
#         while (( $restartS <= $endRestart )); do
#           restartStep=$prefixRestart$restartS
#           InputDir="$dirOut/$prefixC1$prefixC2.$conc/$restartStep"
					 InputDir="$dirOut/$prefixC1$prefixC2.$conc/$dirtrajOut"
           repeatCount=$repeatStart
           while (( $(echo "$repeatCount <= $repeatEnd" | bc -l) )); do
             particleStep=$begparticle
             InputBDName="$prefixC1$prefixC2.$conc.$ScaleF.1microsecond.$Numparticle.$repeatCount"
             while (( $particleStep <= $Numparticle)); do
               TrajName="$InputDir/$InputBDName.0.$particleStep"
               outName="$InputDir/$InputBDName.$particleStep"
               if [ -f "$TrajName.rb-traj" ]; then
                 sed "s|TRAJNAME|$TrajName|g; s|STRINDIR|$STRindir|g; s/C2NAME/$nameC2/g; s|OUTPUTTRAJ|$outName|g; s|SKIP|$skip|g; s|BEG|$beg|; s|END|$end|g;" "$dirScript/$nameScript" > "$dirOut/$tempScript"
                 vmd -dispdev text < "$dirOut/$tempScript"
               else
                 echo "$TrajName.rb-traj does not exist; next BD trajectory."
               fi
               particleStep=$(($particleStep + $stepparticle))
             done
             repeatCount=$(echo $repeatCount + $Drepeat | bc)
           done
#           restartS=$(echo $restartS + $stepRestart | bc)
#          done
       done
    done
  done
done
