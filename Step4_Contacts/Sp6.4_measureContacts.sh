#! /bin/bash -x

## stop on errors
set -e
shopt -s expand_aliases
alias vmdd='vmd -dispdev text'
#To be modulated for being template script
repeatStart=1
repeatEnd=16
ContiIndex=1
RestartIndex=1

##Task: measure contatcs between C2 snapshots from BD with the ensemble structures without a combined trajectory
##Assumption1: BD trajectories from any source, eg. DGX2 or Summit, are all converted to the same foreamt with the same naming;
## and are deposited to the same set of directories
##Assumption2: BD fragments are all concatenated to 1 single long trajectory

##Variables;  Ion concentration/Vdw Scaling
ScalingList="1"
concList=".15"

#Variables;
#prefixesC1= background structure
prefixesC1="Mega_2QCR6"
#prefixesC2= diffusing particle
prefixesC2="cytC_pro"

##Variables; Number of trajectory index & &restart & system label [which is system dependent]
sysNameL="PC_2QCR6"
Numparticle=20
begparticle=1
stepparticle=1
frameOutputFrequency=1000
Drepeat=1 #step of increment
dirRestart="sp$ContiIndex.$RestartIndex"
STRindirC1="/Scr/delcck/Megacomplex/Jacob/Structure/Megacomplex"
dirtrajOut="Combine"

##Variables for cutoff measure [in MD form]
skip=1
beg=0
end=-1
cutOff=4
##Variables for namdenergy
swNum=10
cutNum=12
temperature=300

##Scripts to be sourced
ContactScript="Measure_contacts_noCombine_noHHdist.tcl"
tempScript="Contacts_temp"
dirScript="/Scr/delcck/Megacomplex/Jacob/Analysis"

for sysName in $sysNameL; do
  ##Variables; directories
  dirOut="/Scr/delcck/Megacomplex/Jacob/Analysis/$sysName"

  ###Structure directory
  STRindirC2="/Scr/delcck/Megacomplex/Jacob/Structure/cytC"
  suffixC1="contact"
  for prefixC1 in $prefixesC1; do
  	for prefixC2 in $prefixesC2; do
      for ScaleF in $ScalingList; do
  	     for conc in $concList; do
#            inDir="$dirOut/$prefixC1$prefixC2.$conc/$dirRestart"
            inDir="$dirOut/$prefixC1$prefixC2.$conc/$dirtrajOut"
            refpsfName="$STRindirC1/$prefixC1.$suffixC1.psf"
            refpdbName="$STRC1/$prefixC1.$suffixC1.pdb"
            C2psf="$STRindirC2/$prefixC2.aligned.psf"
            repeatCount=$repeatStart
            while (( $(echo "$repeatCount <= $repeatEnd" | bc -l) )); do
              particleStep=$begparticle
              InputBDName="$prefixC1$prefixC2.$conc.$ScaleF.1microsecond.$Numparticle.$repeatCount"
              while (( $particleStep <= $Numparticle )); do
                TrajName="$inDir/$InputBDName.$particleStep.dcd"
                outName="$inDir/$InputBDName.$particleStep"
                tempName="$inDir/$tempScript.$repeatCount.$particleStep.tcl"
                if [ -f "$TrajName" ]; then
                  sed "s|TRAJNAME|$TrajName|g; s|TRAJPSF|$C2psf|g; s|REFPSF|$refpsfName|g; s|REFPDB|$refpdbName|g; s|SKIP|$skip|g; s|BEG|$beg|; s|END|$end|g; s|MEMT|$sysName|g; s|OUTNAME|$outName|g; s|CCOFF|$cutOff|g;" "$dirScript/$ContactScript" > "$tempName"
                  vmdd < "$tempName"
                else
                  echo "$TrajName does not exist; next BD trajectory."
                fi
                particleStep=$(($particleStep + $stepparticle))
              done
              repeatCount=$(echo $repeatCount + $Drepeat | bc)
            done
         done
      done
    done
  done
done
