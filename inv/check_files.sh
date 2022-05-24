#!/bin/bash

# Checks existence and non-existence of gadgetron files
preproc=$1

declare -a MISSING_FILES

for image in $(ls /project/mscamras/gadgetron/datasets-new/*/*/*.nii.gz); do
    
    if [ $preproc == 'orig' ]; then
        file=$image

    elif [ $preproc == 'n4' ]; then
        file=$(dirname "$image")/n4/$(basename "$image" .nii.gz)_n4.nii.gz

    elif [ $preproc == 'reg' ]; then
        if [[ "$image" =~ 'FLAIR' ]]; then
            file=$(dirname "$image")/reg/$(basename "$image" .nii.gz)_n4_reg.nii.gz
        elif [[ "$image" =~ 'MPRAGE' ]]; then
            continue
        fi

    #elif [ $preproc == 'bet' ]; then 
    #    if [[ "$image" =~ 'FLAIR' ]]; then
    #        continue
    #    elif [[ "$image" =~ 'MPRAGE' ]]; then
    #        file=$(dirname $image)/bet/$(basename $image .nii.gz)_n4_brain.nii.gz #$(sed 's/.nii.gz/_n4_brain.nii.gz/g' <<< "$image")
    #    fi
    #
    #elif [ $preproc == 'betR' ]; then 
    #    if [[ "$image" =~ 'FLAIR' ]]; then
    #        continue
    #    elif [[ "$image" =~ 'MPRAGE' ]]; then
    #        file=$(dirname $image)/betR/$(basename $image .nii.gz)_n4_brain.nii.gz #$(sed 's/.nii.gz/_n4_brain.nii.gz/g' <<< "$image")
    #    fi
    #
    #elif [ $preproc == 'ANTsBrainExt' ]; then 
    #    if [[ "$image" =~ 'FLAIR' ]]; then
    #        continue
    #    elif [[ "$image" =~ 'MPRAGE' ]]; then
    #        file=$(dirname $image)/ANTsBrainExt/$(basename $image .nii.gz)_n4 #$(sed 's/.nii.gz/_n4_brain.nii.gz/g' <<< "$image")
    #    fi

    elif [ $preproc == 'brain' ]; then 
        if [[ "$image" =~ 'FLAIR' ]]; then
            file=$(dirname "$image")/mass/$(basename "$image" .nii.gz)_n4_reg_brain.nii.gz
        elif [[ "$image" =~ 'MPRAGE' ]]; then
            file=$(dirname "$image")/mass/$(basename "$image" .nii.gz)_n4_brain.nii.gz
        fi

    elif [ $preproc == 'brainmask' ]; then 
        if [[ "$image" =~ 'MPRAGE' ]]; then
            file=$(dirname "$image")/mass/$(basename "$image" .nii.gz)_n4_brainmask.nii.gz
        elif [[ "$image" =~ 'FLAIR' ]]; then
            continue
        fi
    
    elif [ $preproc == 'JLF_thal' ]; then
        if [[ "$image" =~ 'MPRAGE' ]]; then
            file="$(dirname $image)/JLF_thal/$(basename $image .nii.gz)_n4_brain" # a directory; not a file
        elif [[ "$image" =~ 'FLAIR' ]]; then
            continue
        fi
        

    elif [ $preproc == 'JLF_WMGM' ]; then
        if [[ "$image" =~ 'MPRAGE' ]]; then
            file="$(dirname $image)/JLF_WMGM/$(basename $image .nii.gz)_n4_brain" # a directory; not a file
        elif [[ "$image" =~ 'FLAIR' ]]; then
            continue
        fi

    elif [ $preproc == 'fused_thal_mask' ]; then 
        if [[ "$image" =~ 'MPRAGE' ]]; then
            file="$(dirname $image)/JLF_thal/$(basename $image .nii.gz)_n4_brain/fused_thal_mask.nii.gz"
        elif [[ "$image" =~ 'FLAIR' ]]; then
            continue
        fi

    elif [ $preproc == 'fused_wmgm_labels' ]; then 
        if [[ "$image" =~ 'MPRAGE' ]]; then
            file="$(dirname $image)/JLF_WMGM/$(basename $image .nii.gz)_n4_brain/fused_wmgm_labels.nii.gz"
        elif [[ "$image" =~ 'FLAIR' ]]; then
            continue
        fi

    elif [ $preproc == 'Atropos' ]; then 
        if [[ "$image" =~ 'MPRAGE' ]]; then
            file="$(dirname $image)/Atropos/$(basename $image .nii.gz)_n4_brain_atropos_seg.nii.gz"
        elif [[ "$image" =~ 'FLAIR' ]]; then
            continue
        fi

    elif [ $preproc == 'FAST' ]; then 
        if [[ "$image" =~ 'MPRAGE' ]]; then
            file="$(dirname $image)/FAST/$(basename $image .nii.gz)_n4_brain_seg.nii.gz"
        elif [[ "$image" =~ 'FLAIR' ]]; then
            continue
        fi

    elif [ $preproc == 'FIRST' ]; then 
        if [[ "$image" =~ 'MPRAGE' ]]; then
            file="$(dirname $image)/FIRST/$(basename $image .nii.gz)_n4_brain_all_none_firstseg.nii.gz"
        elif [[ "$image" =~ 'FLAIR' ]]; then
            continue
        fi
    
    elif [ $preproc == 'mimosa' ]; then 
        if [[ "$image" =~ 'MPRAGE' ]]; then
            file="$(dirname $image)/mimosa/$(basename $image .nii.gz)_n4_brain/bin_mask_0.2.nii.gz"
        elif [[ "$image" =~ 'FLAIR' ]]; then
            continue
        fi

    else
        echo "Enter correct preproc parameters from allowable options: 'orig', 'n4', 'reg', 'brain', 'brainmask', 'JLF_thal', \
        'JLF_WMGM', 'fused_wmgm_labels', 'fused_thal_mask', 'Atropos', 'FAST', 'FIRST', 'mimosa'"
        exit
    fi

    # Check file existence
    if [ ! -e $file ]; then 
        MISSING_FILES+=($file)
    fi
done 

# Print results
printf "There are %s files missing.\n" "${#MISSING_FILES[@]}"
printf "%s\n" ${MISSING_FILES[@]}