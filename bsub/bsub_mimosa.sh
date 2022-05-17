#!/bin/bash
module load fsl

# Get T1s
missing_outfiles=($(bash inv/check_files.sh 'mimosa'))

i=0 # for naming jobs
rm -f logs/mimosa.log # clear previous logs
# Pair mprages with masks, flairs then bsub mimosa
for mprage in $(find /project/mscamras/gadgetron/datasets-new -name *n4_brain.nii.gz); do 
    
    if [[ "${missing_outfiles[*]}" =~ "$(basename $mprage .nii.gz)" ]]; then
    # run mimosa only is file is missing
        if [[ "$mprage" =~ 'MPRAGE_SAG_TFL_ND_' ]]; then
            flair=$(find $(dirname "$mprage") -name *FLAIR_SAG_VFL_ND_n4_reg_brain.nii.gz)
        elif [[ "$mprage" =~ 'MPRAGE_SAG_TFL_NDa' ]]; then
            flair=$(find $(dirname "$mprage") -name *FLAIR_SAG_VFL_NDa_n4_reg_brain.nii.gz)
        fi
    
        brain_mask=$(find $(dirname "$mprage") -name $(sed 's/brain.nii.gz/brainmask.nii.gz/g' <<< $(basename "$mprage")))
    
        printf "Running mimosa:\nMPRAGE:%s\nFLAIR:%s\nMask:%s\n" "$mprage" "$flair" "$brain_mask"
        bsub -m "pennsive01 pennsive03 pennsive04 pennsive05 silver01 amber04" -J mimosa_"$i" -o logs/mimosa.log -e logs/mimosa.log Rscript vols/run_mimosa.R "$mprage" "$flair" "$brain_mask"
        ((i++))
    fi
done


