#!/bin/bash
module load fsl

mkdir -p logs/first data/v5/derivatives/first

for t1 in $(find data/v5/derivatives/qsiprep -path '*masked_T1w.nii.gz' -not -path '*MNI*'); do
    # if file is missing run program
    sub=$(echo $t1 | cut -d/ -f5) # get subject
    out=$(echo ${t1%%.*} | sed 's/qsiprep/first/g')
    bsub -J first -oo logs/first/$sub.log -eo logs/first/$sub.log \
        run_first_all -b -s L_Accu,L_Amyg,L_Caud,L_Hipp,L_Pall,L_Puta,L_Thal,R_Accu,R_Amyg,R_Caud,R_Hipp,R_Pall,R_Puta,R_Thal \
        -i $t1 -o $out
done