#!/bin/bash
module load fsl

# Get T1s
missing_outfiles=($(bash inv/check_files.sh 'FIRST' | sed '1d'))

i=0 # for naming jobs
rm -f logs/first.log # clear previous logs
# Pair mprages with masks, flairs then bsub mimosa

for t1 in $(find /project/mscamras/gadgetron/datasets-new/ -name *brain_n4.nii.gz | grep MPRAGE); do
    # if file is missing run program
    out_dir=$(dirname t1)/../FIRST
    if [[ "${missing_outfiles[*]}" =~ "$(basename $t1 .nii.gz)" ]]; then
        mkdir -p $out_dir
        bsub -m "pennsive01 pennsive03 pennsive04 pennsive05 silver01 amber04" -J first_"$i" -o logs/first.log -e logs/first.log \
            run_first_all -b -s L_Accu,L_Amyg,L_Caud,L_Hipp,L_Pall,L_Puta,L_Thal,R_Accu,R_Amyg,R_Caud,R_Hipp,R_Pall,R_Puta,R_Thal \
            -i "$t1" -o "$out_dir"/$(basename $t1 .nii.gz)
        ((++i))
    fi
done