#! /bin/bash -x

## stop on errors
set -e
shopt -s expand_aliases
alias vmdd='vmd -dispdev text'

###Task: Make use of "Combine_C1C2.tcl", which is assumed to be at the same path as this script, to generate dcds
##that include both bc1 and cyt. c2.
##The combined trajectories will then be deposited to separate directories labelled by the corresponding
## (i) Redox pair state; (ii) Ion concentration; (iii) Number of restarts in the overall BD trajectory

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
sysNameL="PC_2QCR6"
prefixRestart="sp1."
begRestart=1
endRestart=1
stepRestart=1
frameOutputFrequency=1000
repeatStart=1
repeatEnd=16
Drepeat=1 #step of increment
prefixRestart="sp1."
dirCombine="Combine"

##Variables for the output rb-trajs [in BD form]; and the cutoff for determining contacts
skip="100"
beg="+3"
range="3-14"  #only including position information

temperature=300

for sysName in $sysNameL; do
	##Variables; directories
	dirOut="/Scr/delcck/Megacomplex/Jacob/Analysis/$sysName"
	for prefixC1 in $prefixesC1; do
		for prefixC2 in $prefixesC2; do
    	for ScaleF in $ScalingList; do
	     for conc in $concList; do
         restartS=$begRestart
         while (( $restartS <= $endRestart )); do
           restartStep=$prefixRestart$restartS
           #InputDir="$dirOut/$prefixC1$prefixC2.$conc/$restartStep"
					 InputDir="$dirOut/$prefixC1$prefixC2.$conc/$dirCombine"
					 mkdir -p "$InputDir"
           repeatCount=$repeatStart
           while (( $repeatCount <= $repeatEnd )); do
             particleStep=$begparticle
             InputBDName="$prefixC1$prefixC2.$conc.$ScaleF.1microsecond.$Numparticle.$repeatCount"
             while (( $particleStep <= $Numparticle )); do
               outName="$InputDir/$InputBDName.$particleStep.PosOri"
               tempName="$InputDir/$InputBDName.$particleStep.temp"
               TrajName="$InputDir/$InputBDName.0.$particleStep"
               ##-------
               if [ ! -f "$outName.dat" ]; then
               	if [ -f "$TrajName.rb-traj" ]; then
                 	tail -n +3 "$TrajName.rb-traj" | cut -d ' ' -f $range > "$tempName.rb-traj"
                  #awk -v skipV="$skip" 'NR % skipV == 1' "$tempName.rb-traj" > "$outName.dat"
                  awk 'NR % 100 == 1' "$tempName.rb-traj" > "$outName.dat"
               	else
                 	echo "$TrajName.rb-traj does not exist; next BD trajectory."
               	fi
   						 fi
               particleStep=$(($particleStep + $stepparticle))
             done
             repeatCount=$(echo $repeatCount + $Drepeat | bc)
           done
           restartS=$(echo $restartS + $stepRestart | bc)
          done
          rm -f "$dirOut/$prefixC1$prefixC2.$conc/$restartStep/*temp*rb-traj"
       done
    done
  done
done
done
