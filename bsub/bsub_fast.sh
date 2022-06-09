#!/bin/bash
module load ANTs

# Get T1s
missing_outfiles=($(bash inv/check_files.sh 'FAST' | sed '1d'))

i=0 # for naming jobs
rm -f logs/fast.log # clear previous logs
# Pair mprages with masks, flairs then bsub mimosa

for t1 in $(find /project/mscamras/gadgetron/datasets-new/ -name *brain_n4.nii.gz | grep MPRAGE); do
    # if file is missing run program
    if [[ "${missing_outfiles[*]}" =~ "$(basename $t1 .nii.gz)" ]]; then
        bsub -m "pennsive01 pennsive03 pennsive04 pennsive05 silver01 amber04" -J fast_"$i" -o logs/fast.log -e logs/fast.log Rscript vols/fast.R "$t1" $(dirname $t1)/..
        ((++i))
    fi

done