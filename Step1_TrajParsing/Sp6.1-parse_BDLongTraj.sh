#! /bin/bash -x

## stop on errors
set -e
shopt -s expand_aliases
alias vmdd='vmd -dispdev text'

##Task: parse all BD trajectories in individual trajectories; this process involves working on multiple directories.
## Goal: parse BD trajectories and deposit individal trajectories to separate directory labelled by the corresponding
## (i) Redox pair state; (ii) Ion concentration; (iii) Number of trajectory index; (iv) number of restart

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
sysName="PC_2QCR6"
prefixRestart="sp1."
begRestart=1
endRestart=1
stepRestart=1
frameOutputFrequency=1000
repeatStart=1
repeatEnd=16
Drepeat=1 #step of increment

##Variables; directories
dirLocalBD="/Scr/delcck/Megacomplex/Jacob/ProductionRun/$sysName"
dirOut="/Scr/delcck/Megacomplex/Jacob/Analysis/$sysName"
nameScript="Split_trajectories.tcl"
dirScript="/Scr/delcck/Megacomplex/Jacob/Analysis"
for prefixC1 in $prefixesC1; do
	for prefixC2 in $prefixesC2; do
    for ScaleF in $ScalingList; do
	     for conc in $concList; do
         mkdir -p "$dirOut/$prefixC1$prefixC2.$conc"
         restartS=$begRestart
         while (( $restartS <= $endRestart )); do
           repeatCount=$repeatStart
           while (( $(echo "$repeatCount <= $repeatEnd" | bc -l) )); do
             restartStep=$prefixRestart$restartS
             InputDir="$dirLocalBD/$restartStep/DGX2"
             InputBDName="$prefixC1$prefixC2.$conc.$ScaleF.1microsecond.$Numparticle.$repeatCount.0"
             OutputDir="$dirOut/$prefixC1$prefixC2.$conc/$restartStep"
             if [ -d "$InputDir" ]; then
               mkdir -p "$dirOut/$prefixC1$prefixC2.$conc/$restartStep"
               echo "Making directory $dirOut/$prefixC1$prefixC2.$conc/$restartStep"
               if [ -f "$InputDir/$InputBDName.rigid" ]; then
                 echo "Procesing $InputBDName"
                 tail -n -1 "$InputDir/$InputBDName.rigid" | cut -d ' ' -f 1 > "$OutputDir/temp.txt"
                 trajLength=$(($(cat $OutputDir/temp.txt)/$frameOutputFrequency))
                 vmdd -args $InputBDName $InputDir $OutputDir $trajLength < "$dirScript/$nameScript"
               else
                 echo "$InputBDName.rigid does not exit; next BD trajectory."
               fi
             else
               echo "$InputDir does not exit."
             fi
             repeatCount=$(echo $repeatCount + $Drepeat | bc)
		       done
           restartS=$(echo $restartS + $stepRestart | bc)
   			 done
       done
    done
  done
done
