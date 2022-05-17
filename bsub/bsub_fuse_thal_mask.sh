#!/bin/bash

# get skull-stripped T1s
missing_outfiles=$(bash inv/check_files.sh 'fused_thal_mask' | sed '1d')

i=0 # for naming jobs
rm -f logs/fusethal.log # Clear logs

for t1 in $(find /project/mscamras/gadgetron/datasets-new/ -name *n4_brain.nii.gz); do
    # if file is missing run program
    if [[ "${missing_outfiles[*]}" =~ "$(basename $t1 .nii.gz)" ]]; then
        bsub -m "pennsive01 pennsive03 pennsive04 pennsive05 silver01 amber04" -J fusethal_"$i" -o logs/fusethal.log -e logs/fusethal.log bash vols/fuse_thal_masks.sh "$t1"
        ((++i))
    fi
done