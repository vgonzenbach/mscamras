#!/bin/bash
module load c3d

# resample dtifit results to fit segmentation masks
for tensor in FA MD RD AD; do
    for f in $(find data/v5/derivatives/dtifit -name *${tensor}.nii.gz); do
        out=$(echo $f | sed "s/$tensor.nii.gz/desc-resampled_$tensor.nii.gz/g")
        bsub -J resampling -o logs/resampling.log -e logs/resampling.log c3d $f -resample 193x229x193 -o $out
    done
done