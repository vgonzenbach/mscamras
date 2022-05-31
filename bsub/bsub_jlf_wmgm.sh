#!/bin/bash

# get skull-stripped T1s
missing_outfiles=($(bash inv/check_files.sh 'JLF_WMGM' | sed '1d'))
i=0 # for naming jobs
rm -f logs/jlfwmgm.log # Clear logs

for t1 in $(find /project/mscamras/gadgetron/datasets-new/ -name *brain_n4.nii.gz | grep MPRAGE); do
    # if file is missing run program
    if [[ "${missing_outfiles[*]}" =~ "$(basename $t1 .nii.gz)" ]]; then
        bsub -m "pennsive01 pennsive03 pennsive04 pennsive05 silver01 amber04" -J jlfwmgm_"$i" -o logs/jlfwmgm.log -e logs/jlfwmgm.log Rscript vols/jlf.R WMGM "$t1" "$(dirname $t1)"
        ((++i))
    fi
done