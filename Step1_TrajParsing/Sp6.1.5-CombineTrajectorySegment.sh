#!/bin/bash

#Task: generate .sh and configuration files for running BD
## stop on errors
set -e

##Variables
runDir="/Scr/delcck/Megacomplex/Jacob/ProductionRun"
sysName="CL_2QCR6"
#sysName="PC250Fe"

ScalingList="1"
concList=".15" #monovalent electrolyte (M)
Temp=300
Tstep="200e-6"  # equivalent to 200fs
step=50000000  # equivalent to 10 microsecond
interact="#"                            # on/off for interaction among diffusive particles

#Variables;
#prefixesC1= background structure
prefixesC1="Mega_2QCR6"
#prefixesC2= diffusing particle
prefixesC2="cytC_pro"


##Variables; Number of trajectory index & &restart & system label [which is system dependent]
Numparticle=20
prefixRestart="sp1."
begRestart=1
endRestart=6
stepRestart=1
frameOutputFrequency=1000
repeatStart=1
repeatEnd=16
Drepeat=1 #step of increment
Numparticle=20
begparticle=1
stepparticle=1

##Variables for the output dcds [in MD form]
skip=100
beg=0
end=-1

# parameters
FileDir="/Scr/delcck/Megacomplex/Jacob/ProductionRun/$sysName"
dirOut="/Scr/delcck/Megacomplex/Jacob/Analysis/$sysName"
dirtrajOut="Combine.$begRestart.to.$endRestart"
dirtrajOutFinal="Combine"


for prefixC1 in $prefixesC1; do
  for prefixC2 in $prefixesC2; do
    for ScaleF in $ScalingList; do
      for conc in $concList; do
        mkdir -p "$dirOut/$prefixC1$prefixC2.$conc/$dirtrajOut"
        mkdir -p "$dirOut/$prefixC1$prefixC2.$conc/$dirtrajOutFinal"
           #outDirC1C2Redox="$FileDir/$prefixC1$prefixC1$conc/$prefixRestart$begRestart"
           #mkdir -p "$outDirC1C2Redox"
           #-- loop over repeat
           repeatCount=$repeatStart
           while (( $(echo "$repeatCount <= $repeatEnd" | bc -l) )); do
             particleStep=$begparticle
             InputBDName="$prefixC1$prefixC2.$conc.$ScaleF.1microsecond.$Numparticle.$repeatCount.0"
             #-- loop over number of particle
             while (( $particleStep <= $Numparticle)); do
               restartS=$begRestart
               #-- loop over restart
               while (( $restartS <= $endRestart )); do
                 restartStep="$prefixRestart$restartS"
                 InputDir="$dirOut/$prefixC1$prefixC2.$conc/$restartStep"
                 TrajName="$InputDir/$InputBDName.$particleStep"
                 outtrajName="$dirOut/$prefixC1$prefixC2.$conc/$dirtrajOut/$InputBDName.$particleStep"
                 tempTime="$dirOut/$prefixC1$prefixC2.$conc/$dirtrajOut/temp"
                 tempBD1="$dirOut/$prefixC1$prefixC2.$conc/$dirtrajOut/temp"
                 tempBD2="$dirOut/$prefixC1$prefixC2.$conc/$dirtrajOut/temp.new"
                 if [ -f "$TrajName.rb-traj" ]; then
                   echo "$TrajName.rb-traj exists."
                   if [ ! -f "$outtrajName.rb-traj" ]; then
                     cp "$TrajName.rb-traj" "$outtrajName.rb-traj"
                   else
                     cp "$outtrajName.rb-traj" "$outtrajName.temp.rb-traj"
                     tail -n -1 "$outtrajName.rb-traj" | cut -d ' ' -f 1 > "$tempTime.txt"
                     varStep=$(cat "$tempTime.txt")
                     tail -n +3 "$TrajName.rb-traj" > "$tempBD1.rb-traj"
                     awk -v VAR="$varStep" '$1+=VAR' "$tempBD1.rb-traj" > "$tempBD2.rb-traj"
                     cat "$outtrajName.temp.rb-traj" "$tempBD2.rb-traj" > "$outtrajName.rb-traj"
                   fi
                 else
                   echo "$TrajName.rb-traj does not exist; next BD trajectory."
                 fi
                 restartS=$(echo $restartS + $stepRestart | bc)
               done
               particleStep=$(($particleStep + $stepparticle))
             done
             repeatCount=$(echo $repeatCount + $Drepeat | bc)
            done
            rm -f "$dirOut/$prefixC1$prefixC2.$conc/$dirtrajOut/*temp*"
            mv "$dirOut/$prefixC1$prefixC2.$conc/$dirtrajOut/*rb-traj"  "$dirOut/$prefixC1$prefixC2.$conc/$dirtrajOutFinal/."
          done
        done
      done
done
