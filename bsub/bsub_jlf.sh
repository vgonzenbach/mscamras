#!/bin/bash
module load ANTs2/2.2.0-111

# get skull-stripped T1s
mode=$1
if [ $# -eq 0 ]; then echo "Enter valid 'mode' argument: WMGM, thal"; exit; fi
missing_outfiles=($(bash inv/check_files.sh JLF_${mode} | sed '1d'))
i=0 # for naming jobs
rm -f logs/jlf${mode}.log # Clear logs

for t1 in $(find /project/mscamras/gadgetron/datasets-new/ -name *brain_n4.nii.gz | grep MPRAGE); do
    # if file is missing run program
    if [[ "${missing_outfiles[*]}" =~ "$(basename $t1 .nii.gz)" ]]; then
        bsub -m "pennsive01 pennsive03 pennsive04 pennsive05 silver01 amber04" -J jlf${mode}_"$i" -o logs/jlf${mode}.log -e logs/jlf${mode}.log Rscript vols/jlf.R ${mode} "$t1" $(dirname $t1)/..
        ((++i))
    fi
done