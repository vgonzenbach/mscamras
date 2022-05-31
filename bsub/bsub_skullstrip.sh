# Run skull stripping on n4 images
module load ANTs2/2.2.0-111
module load afni_openmp/17.1.07
module load fsl
module load MASS
module load dramms/1.4.1

# Load paths
if [ "$#" == 0 ]; then echo 'Enter argument: "MPRAGE" or "FLAIR"'; exit; fi
rm -f logs/ss.log
if [ "$1" == "MPRAGE" ]; then

    for mprage in $(ls /project/mscamras/gadgetron/datasets-new/*/*/*.nii.gz | grep MPRAGE); do
        # TODO: add existence check to not preprocess when output exists + add argument to force reprocessing

        dest_dir=$(dirname "$mprage")/brain
        mkdir -p "$dest_dir"
        out_brain="$dest_dir"/$(basename "$mprage" .nii.gz)_brain.nii.gz

        if [ ! -e "$out_brain" ]; then
            printf "Skull stripping %s" "$mprage"
            #Rscript preproc/apply_brainmask.R "$flair" "$brain_mask"
            dir=$(echo $(dirname $mprage) | sed 's/gadgetron\/datasets-new/Data/g')
            brainmask="$dir"/analysis/mass/$(basename $mprage .nii.gz | sed 's/^.*\(MPRAGE\)/\1/g')_n4_brainmask.nii.gz
            bsub -m "pennsive01 pennsive03 pennsive04 pennsive05 silver01 amber04" -o logs/ss.log -e logs/ss.log Rscript preproc/apply_brainmask.R "$mprage" "$brainmask" "$dest_dir"

        fi
    done

elif [ "$1" == "FLAIR" ]; then

    for flair in $(ls /project/mscamras/gadgetron/datasets-new/*/*/reg/*.nii.gz); do
        # TODO: add existence check to not preprocess when output exists + add argument to force reprocessing

        dest_dir=$(dirname "$flair")/../brain
        mkdir -p "$dest_dir"

        out_brain="$dest_dir"/$(basename "$flair" .nii.gz)_brain.nii.gz

        if [ ! -e "$out_brain" ]; then
            
            printf "Skull stripping %s\n" "$flair"
            #Rscript preproc/apply_brainmask.R "$flair" "$brain_mask"
            dir=$(echo $(dirname $flair) | sed 's/gadgetron\/datasets-new/Data/g' | cut -d/ -f1-6)
            brainmask="$dir"/analysis/mass/$(basename $flair .nii.gz | sed 's/_reg//g; s/VFL/TFL/g; s/FLAIR/MPRAGE/g; s/^.*\(MPRAGE\)/\1/g')_n4_brainmask.nii.gz
            bsub -m "pennsive01 pennsive03 pennsive04 pennsive05 silver01 amber04" -o logs/ss.log -e logs/ss.log Rscript preproc/apply_brainmask.R "$flair" "$brainmask" "$dest_dir"

        fi
    done
fi