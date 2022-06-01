#!/bin/bash

# get skull-stripped T1s
mode=$1
if [ $# -eq 0 ]; then echo "Enter valid 'mode' argument: WMGM, thal"; exit; fi
missing_outfiles=$(bash inv/check_files.sh "fused_${mode}_seg" | sed '1d')
i=0 # for naming jobs
rm -f logs/fuse${mode}.log # Clear logs

for t1 in $(find /project/mscamras/gadgetron/datasets-new/ -name *n4_brain.nii.gz); do
    # if file is missing run program
    if [[ "${missing_outfiles[*]}" =~ "$(basename $t1 .nii.gz)" ]]; then
        bsub -m "pennsive01 pennsive03 pennsive04 pennsive05 silver01 amber04" -J fuse${mode}_"$i" -o logs/fuse${mode}.log -e logs/fuse${mode}.log bash vols/fuse_jlf_seg.sh ${mode} "$t1"
        ((++i))
    fi
done