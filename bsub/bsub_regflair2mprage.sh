#!/bin/bash
module load ANTs2/2.2.0-111
cd $(dirname "$0")/..
missing_outfiles=($(bash inv/check_files.sh reg))

rm -f logs/reg.log
i=0
for flair in $(ls /project/mscamras/Data/*/*/analysis/*n4.nii.gz | grep FLAIR | grep ND ); do

    # get corresponding mprage
    if [[ "$flair" =~ "ND_n4.nii.gz" ]]; then
        mprage=$(find $(dirname "$flair") -name *MPRAGE_SAG_TFL_ND_n4.nii.gz) # get corresponding mprage
        
    elif [[ "$flair" =~ "NDa_n4.nii.gz" ]]; then
        mprage=$(find $(dirname "$flair") -name *MPRAGE_SAG_TFL_NDa_n4.nii.gz)

    fi  

    onsc_flair_dir=$(dirname $flair |  sed 's/Data/gadgetron\/datasets-new/g; s/analysis//g')
    onsc_flair=$(find $onsc_flair_dir -name *$(basename $flair | sed 's/_n4.nii.gz/.nii.gz/g'))
    # submit registration job
    echo $onsc_flair
    
    if [[ "${missing_outfiles[*]}" =~ $(basename "$onsc_flair" .nii.gz) ]]; then
        printf "Registering %s to %s. Applying to %s\n" $flair $mprage $onsc_flair
        bsub -J reg_$i -m "pennsive01 pennsive03 pennsive04 pennsive05 silver01 amber04" -o logs/reg.log -e logs/reg.log Rscript preproc/reg_flair2mprage.R "$flair" "$mprage" "$onsc_flair"
        ((++i))
    fi
done

echo "All registration jobs submitted successfully"