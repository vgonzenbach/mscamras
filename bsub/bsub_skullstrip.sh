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

    for mprage in $(ls /project/mscamras/gadgetron/datasets-new/*/*/n4/*.nii.gz | grep MPRAGE); do
        # TODO: add existence check to not preprocess when output exists + add argument to force reprocessing

        dest_dir=$(dirname "$mprage")/../mass
        mkdir -p "$dest_dir"
        out_brain="$dest_dir"/$(basename "$mprage" .nii.gz)_brain.nii.gz

        if [ ! -e "$out_brain" ]; then
            printf "Skull stripping %s" "$mprage"
            bsub -o logs/ss.log -e logs/ss.log singularity run -e -B /project -B /scratch /project/singularity_images/mass_latest.sif \
            -in "$mprage" -dest "$dest_dir" -ref /project/MRI_Templates/MASS_Templates/WithCerebellum -NOQ -mem 25
        fi
    done

elif [ "$1" == "FLAIR" ]; then

    for flair in $(ls /project/mscamras/gadgetron/datasets-new/*/*/reg/*.nii.gz); do

        if [[ "$flair" =~ "ND_n4_reg.nii.gz" ]]; then

            brain_mask=$(find $(dirname "$flair")/../mass -name *ND_n4_brainmask.nii.gz) # get mprage brain_mask
            
        elif [[ "$flair" =~ "NDa_n4_reg.nii.gz" ]]; then
            
            brain_mask=$(find $(dirname "$flair")/../mass -name *NDa_n4_brainmask.nii.gz)

        else
            echo "Not found"
        fi

        out_brain=$(dirname "$brain_mask")/$(basename "$flair" .nii.gz)_brain.nii.gz
        if [ ! -e "$out_brain" ]; then
            printf "Applying %s to %s\n" "$brain_mask" "$flair"
            bsub -o logs/ss.log -e logs/ss.log Rscript preproc/apply_brainmask.R "$flair" "$brain_mask"
        fi
    done
fi