#!/bin/bash
cd $(dirname $0)/..
module load ANTs

mkdir -p logs/n4
for t2 in $(find data/v5 -name *T2w.nii.gz); do 
    sub=$(echo $t2 | cut -d/ -f3)    
    out=$(echo $t2 | sed 's/v5/v5\/derivatives\/mimosa/g; s/T2w.nii.gz/desc-n4_T2w.nii.gz/g')
    mkdir -p $(dirname $out)
    bsub -J n4 -oo logs/n4/$sub.log -eo logs/n4/$sub.log N4BiasFieldCorrection -d 3 -i $t2 -o $out
done