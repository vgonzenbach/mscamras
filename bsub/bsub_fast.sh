#!/bin/bash
module load fsl

mkdir -p logs/fast data/v5/derivatives/fast

for t1 in $(find data/v5/derivatives/qsiprep -path '*masked_T1w.nii.gz' -not -path '*MNI*'); do
    # if file is missing run program
    sub=$(echo $t1 | cut -d/ -f5)
    bsub -J fast -oo logs/fast/$sub.log -eo logs/fast/$sub.log Rscript seg/fsl_fast.R $t1
done