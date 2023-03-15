#!/bin/bash
module load fsl
cd $(dirname $0)/..

# mask t1s from qsiprep
mkdir -p logs/mask_t1 
for t1 in $(find data/v5/derivatives/qsiprep -path '*T1w.nii.gz' -not -path '*MNI*'); do
    mask=$(find $(dirname $t1) -name *brain_mask.nii.gz -not -name *MNI*)
    sub=$(echo $t1 | cut -d/ -f5)
    out=$(echo $t1 | sed 's/preproc/masked/g')
    bsub -J mask_t1 -oo logs/mask_t1/$sub.log -eo logs/mask_t1/$sub.log fslmaths $t1 -mas $mask $out
done