# Run skull stripping on n4 images
#!/bin/bash
module load fsl
cd $(dirname $0)/..

# mask flairs before mimosa
mkdir -p logs/mask_flair
for flair in $(find data/v5/derivatives/mimosa -path '*desc-n4reg_T2w.nii.gz'); do

    sub=$(echo $flair | cut -d/ -f5)
    mask=$(find data/v5/derivatives/qsiprep/$sub/anat -name *brain_mask.nii.gz -not -name *MNI*)
    out=$(echo $flair | sed 's/desc-n4reg/desc-n4regmasked/g')
    bsub -J mask_flair -oo logs/mask_flair/$sub.log -eo logs/mask_flair/$sub.log fslmaths $flair -mas $mask $out
done