#!/bin/bash
cd $(dirname $0)/..
module load c3d
module load ANTs

mkdir -p logs/resampling
# resample dtifit results to fit segmentation masks
for tensor in FA MD RD AD; do
    for dwi in $(find data/v5/derivatives/dtifit -name *${tensor}.nii.gz); do
        sub=$(echo $dwi | cut -d/ -f5)
        t1=$(find data/v5/derivatives/qsiprep -name $sub*masked_T1w.nii.gz)
        out_resampled=$(echo $dwi | sed "s/$tensor.nii.gz/desc-resampled_$tensor.nii.gz/g")
        out_resampled_reg=$(echo $dwi | sed "s/$tensor.nii.gz/desc-resampledreg_$tensor.nii.gz/g")
        bsub -J resampling_${tensor}_${sub} -oo logs/resampling/${sub}_${tensor}.log -eo logs/resampling/${sub}_${tensor}.log c3d $dwi -resample 193x229x193 -o $out_resampled
        bsub -J reg_dwi -w resampling_${tensor}_${sub} -ti -o logs/resampling/${sub}_${tensor}.log -e logs/resampling/${sub}_${tensor}.log Rscript preproc/reg_flair2mprage.R $out_resampled $t1 $out_resampled_reg
    done
done