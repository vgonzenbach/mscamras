#!/bin/bash

# Checks existence and non-existence of gadgetron files
preproc=$1

declare -a MISSING_FILES

for image in $(ls /project/mscamras/gadgetron/datasets-new/*/*/*.nii.gz); do
    
    if [ $preproc == 'orig' ]; then
        file=$image

    elif [ $preproc == 'n4' ]; then
        if [[ "$image" =~ 'FLAIR' ]]; then
                file=$(dirname "$image")/n4/$(basename "$image" .nii.gz)_reg_brain_n4.nii.gz
            elif [[ "$image" =~ 'MPRAGE' ]]; then
                file=$(dirname "$image")/n4/$(basename "$image" .nii.gz)_brain_n4.nii.gz
            fi
        

    elif [ $preproc == 'reg' ]; then
        if [[ "$image" =~ 'FLAIR' ]]; then
            file=$(dirname "$image")/reg/$(basename "$image" .nii.gz)_reg.nii.gz
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
            file=$(dirname "$image")/brain/$(basename "$image" .nii.gz)_reg_brain.nii.gz
        elif [[ "$image" =~ 'MPRAGE' ]]; then
            file=$(dirname "$image")/brain/$(basename "$image" .nii.gz)_brain.nii.gz
        fi

    elif [ $preproc == 'brainmask' ]; then 
        if [[ "$image" =~ 'MPRAGE' ]]; then
            file=$(dirname "$image")/mass/$(basename "$image" .nii.gz)_brainmask.nii.gz
        elif [[ "$image" =~ 'FLAIR' ]]; then
            continue
        fi
    
    elif [ $preproc == 'JLF_thal' ]; then
        if [[ "$image" =~ 'MPRAGE' ]]; then
            file="$(dirname $image)/JLF_thal/$(basename $image .nii.gz)_brain_n4" # a directory; not a file
        elif [[ "$image" =~ 'FLAIR' ]]; then
            continue
        fi
        

    elif [ $preproc == 'JLF_WMGM' ]; then
        if [[ "$image" =~ 'MPRAGE' ]]; then
            file="$(dirname $image)/JLF_WMGM/$(basename $image .nii.gz)_brain_n4" # a directory; not a file
        elif [[ "$image" =~ 'FLAIR' ]]; then
            continue
        fi

    elif [ $preproc == 'fused_thal_seg' ]; then 
        if [[ "$image" =~ 'MPRAGE' ]]; then
            file="$(dirname $image)/JLF_thal/$(basename $image .nii.gz)_brain_n4/fused_thal_seg.nii.gz"
        elif [[ "$image" =~ 'FLAIR' ]]; then
            continue
        fi

    elif [ $preproc == 'fused_WMGM_seg' ]; then 
        if [[ "$image" =~ 'MPRAGE' ]]; then
            file="$(dirname $image)/JLF_WMGM/$(basename $image .nii.gz)_brain_n4/fused_WMGM_seg.nii.gz"
        elif [[ "$image" =~ 'FLAIR' ]]; then
            continue
        fi

    elif [ $preproc == 'Atropos' ]; then 
        if [[ "$image" =~ 'MPRAGE' ]]; then
            file="$(dirname $image)/Atropos/$(basename $image .nii.gz)_brain_n4_atropos_seg.nii.gz"
        elif [[ "$image" =~ 'FLAIR' ]]; then
            continue
        fi

    elif [ $preproc == 'FAST' ]; then 
        if [[ "$image" =~ 'MPRAGE' ]]; then
            file="$(dirname $image)/FAST/$(basename $image .nii.gz)_brain_n4_seg.nii.gz"
        elif [[ "$image" =~ 'FLAIR' ]]; then
            continue
        fi

    elif [ $preproc == 'FIRST' ]; then 
        if [[ "$image" =~ 'MPRAGE' ]]; then
            file="$(dirname $image)/FIRST/$(basename $image .nii.gz)_brain_n4_all_none_firstseg.nii.gz"
        elif [[ "$image" =~ 'FLAIR' ]]; then
            continue
        fi
    
    elif [ $preproc == 'mimosa' ]; then 
        if [[ "$image" =~ 'MPRAGE' ]]; then
            file="$(dirname $image)/mimosa/$(basename $image .nii.gz)_brain_n4/bin_mask_0.2.nii.gz"
        elif [[ "$image" =~ 'FLAIR' ]]; then
            continue
        fi

    else
        echo "Enter correct preproc parameters from allowable options: 'orig', 'n4', 'reg', 'brain', 'brainmask', 'JLF_thal', \
        'JLF_WMGM', 'fused_WMGM_seg', 'fused_thal_seg', 'Atropos', 'FAST', 'FIRST', 'mimosa'"
        exit
    fi

    # Check file existence
    if [ ! -e $file ]; then 
        MISSING_FILES+=($file)

    elif [ "$preproc" == "JLF_thal" ] || [ "$preproc" == "JLF_WMGM" ] ; then
            #reg_files=$(find $file -type f || true)
            if [ ! $(find $file -type f | wc -l) -ge 20 ]; then
                MISSING_FILES+=($file)
            fi
    fi
done 

# Print results
printf "There are %s files missing.\n" "${#MISSING_FILES[@]}"
printf "%s\n" ${MISSING_FILES[@]}