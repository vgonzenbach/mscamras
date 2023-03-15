#!/bin/bash
module load ANTs2/2.2.0-111
cd $(dirname "$0")/..

mkdir -p logs/reg
for flair in $(find data/v5/derivatives/mimosa -name '*desc-n4*'); do

    sub=$(echo $flair | cut -d/ -f5)
    t1=$(find data/v5/derivatives/qsiprep -name "${sub}*desc-preproc_T1w.nii.gz" -not -name '*MNI*desc-preproc_T1w.nii.gz')
    out=$(echo $flair | sed 's/desc-n4/desc-n4reg/g')
    # get corresponding mprage
    bsub -J reg_flair -oo logs/reg/$sub.log -eo logs/reg/$sub.log Rscript preproc/reg_flair2mprage.R $flair $t1 $out
done