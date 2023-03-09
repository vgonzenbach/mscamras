#!/bin/bash
module load ANTs

# Get T1s
# Pair mprages with masks, flairs then bsub mimosa
mkdir -p logs/atropos data/v5/derivatives/atropos
for t1 in $(find data/v5/derivatives/qsiprep -path '*masked_T1w.nii.gz' -not -path '*MNI*'); do
    sub=$(echo $t1 | cut -d/ -f5)
    bsub -J atropos -oo logs/atropos/$sub.log -eo logs/atropos/$sub.log Rscript seg/atropos.R ${t1}
done