#!/bin/bash

cd $(dirname "$0")/..
missing_outfiles=($(bash inv/check_files.sh reg))
for flair in $(ls /project/mscamras/gadgetron/datasets-new/*/*/n4/*.nii.gz | grep FLAIR); do

    # get corresponding mprage
    if [[ "$flair" =~ "ND_n4.nii.gz" ]]; then
        mprage=$(find $(dirname "$flair") -name *MPRAGE_SAG_TFL_ND_n4.nii.gz) # get corresponding mprage
        
    elif [[ "$flair" =~ "NDa_n4.nii.gz" ]]; then
        mprage=$(find $(dirname "$flair") -name *MPRAGE_SAG_TFL_NDa_n4.nii.gz)

    fi  

    # submit registration job
    if [[ "${missing_outfiles[*]}" =~ $(basename "$flair" .nii.gz) ]]; then
        printf "Registering %s to %s\n" $flair $mprage
        bsub -o logs/reg.log -e logs/reg.log Rscript preproc/reg_flair2mprage.R "$flair" "$mprage"  
    fi
   
    
done

echo "All registration jobs submitted successfully"