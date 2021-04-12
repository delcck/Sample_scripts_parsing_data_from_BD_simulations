#! /bin/bash -x

## stop on errors
set -e
shopt -s expand_aliases
alias vmdd='vmd -dispdev text'
#Change here
repeatStart=1
repeatEnd=16

##Task: Make use of ".tcl", which is assumed to be at the same path as this script, to measure
## the vdw & elec energy btw constitutents of membrane & cyt C
##along each megacomplex-C bound state trajectory


##Variables;  Ion concentration/Vdw Scaling
ScalingList="1"
concList=".15"

#Variables; Redox pairs
#prefixesC1= background structure
prefixesC1="Mega_2QCR6"
#prefixesC2= diffusing particle
prefixesC2="cytC_pro"

##Variables; Number of trajectory index & &restart & system label [which is system dependent]
Numparticle=20
begparticle=1
stepparticle=1
sysPre="PC_"
sysSuf="_PC"
sysNameL="2QCR6"
boundModeL="C3m1 C3m2 C4m1 C4m2 Qcm1 Qcm2 Membrane"
prefixRestart="sp1."
begRestart=1
endRestart=1
stepRestart=1
frameOutputFrequency=1000
Drepeat=1 #step of increment
prefixRestart="sp1."

##Variables for the output dcds [in MD form]; and the cutoff for determining contacts
skip=1
beg=0
end=-1
cutOff=4
##Variables for namdenergy
swNum=10
cutNum=12
temperature=310



##Scripts to be solved
nameScript="Measure_energy.tcl"
tempScript="Energy.temp.tcl"
dirScript="/Scr/delcck/Megacomplex/Jacob/Analysis"

for sysName in $sysNameL; do
	##Variables; directories
	sysFName=$sysPre$sysName
	dirOut="/Scr/delcck/Megacomplex/Jacob/Analysis/$sysFName"
	for prefixC1 in $prefixesC1; do
		for prefixC2 in $prefixesC2; do
      for ScaleF in $ScalingList; do
	     for conc in $concList; do
         restartS=$begRestart
         OutBDpsfName="$prefixC1$prefixC2.$conc.$ScaleF"
         while (( $restartS <= $endRestart )); do
           restartStep=$prefixRestart$restartS
           mkdir -p "$dirOut/$prefixC1$prefixC2.$conc/$restartStep"
           InputDir="$dirOut/$prefixC1$prefixC2.$conc/$restartStep"
					 psfName="$InputDir/$prefixC1.sampleTraj"
					 for boundMode in $boundModeL; do
						 InputBDName="$sysName$sysSuf.$conc.$boundMode"
						 TrajName="$InputDir/$InputBDName"
						 outName="$TrajName"
						 #redoxD is a label to identify the ene rgy calculations for different systems assuming all temporary files are stored at the same place
						 redoxD="$sysFName.$conc.$boundMode"
						 if [ -f "$TrajName.dcd" ]; then
							 sed "s|TRAJNAME|$TrajName|g; s|PSFN|$psfName|g; s|SKIP|$skip|g; s|BEG|$beg|; s|END|$end|g; s|MEMT|$sysFName|g; s|OUTNAME|$outName|g; s|SWNUM|$swNum|g; s|CUTNUM|$cutNum|g; s|TEMP|$temperature|g; s|REDOXD|$redoxD|g;" "$dirScript/$nameScript" > "$InputDir/$boundMode.$tempScript"
							 vmd -dispdev text < "$InputDir/$boundMode.$tempScript"
						 else
							 echo "$TrajName.dcd does not exist; next BoundMode trajectory."
						 fi
					 done
           restartS=$(echo $restartS + $stepRestart | bc)
				 done
			 done
		 done
	 done
 done
done
