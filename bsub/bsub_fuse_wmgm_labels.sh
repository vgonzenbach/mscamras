#!/bin/bash

# Get all T1s
missing_outfiles=$(bash inv/check_files.sh 'fused_wmgm_labels' | sed '1d') 

i=0 # for naming jobs
rm -f logs/fusewmgm.log # clear logs

for t1 in $(find /project/mscamras/gadgetron/datasets-new/ -name *brain_n4.nii.gz); do
    # run program only if file is missing 
    if [[ "${missing_outfiles[*]}" =~ "$(basename $t1 .nii.gz)" ]]; then
        bsub -m "pennsive01 pennsive03 pennsive04 pennsive05 silver01 amber04" -J fusewmgm_"$i" -o logs/fusewmgm.log -e logs/fusewmgm.log bash vols/fuse_wmgm_labels.sh "$t1"
        ((++i))
    fi
done