#!/bin/bash
module load fsl
cd $(dirname $0)/..

mkdir -p logs/mimosa
for t1 in $(find data/v5/derivatives/qsiprep -name *desc-masked_T1w.nii.gz); do 
    
    sub=$(echo $t1 | cut -d/ -f5)
    flair=$(find data/v5/derivatives/mimosa -name $sub*desc-n4regmasked_T2w.nii.gz)
    mask=$(find $(dirname $t1) -name *brain_mask.nii.gz -not -name *MNI*)
    out_prob=$(echo $flair | sed 's/T2w.nii.gz/label-lesion_probseg.nii.gz/g') # mimosa probability map

    bsub -J mimosa_prob_$sub -oo logs/mimosa/$sub.log -eo logs/mimosa/$sub.log Rscript seg/run_mimosa.R $t1 $flair $mask $out_prob
    out_bin=$(echo $out_prob | sed 's/probseg.nii.gz/mask.nii.gz/g') # mimosa lesion mask
    bsub -J mimosa_bin_$sub -w mimosa_prob_$sub -ti -o logs/mimosa/$sub.log -e logs/mimosa/$sub.log fslmaths $out_prob -thr 0.2 $out_bin
done


