# Run skull stripping on n4 images
module load ANTs2/2.2.0-111
module load afni_openmp/17.1.07
module load fsl
module load MASS
module load dramms/1.4.1

mode=$1
# Load paths

if [ "$1" == MPRAGE ]; then

    GADG_MPRAGE=($(cut -d, -f6 file_list+preproc.csv | grep 'gadgetron' | grep 'MPRAGE')) # filter gadgtron
    printf "There were %s MPRAGE scans found.\n" ${#GADG_MPRAGE[@]} 

    for image in ${GADG_MPRAGE[@]}; do
        # TODO: add existence check to not preprocess when output exists + add argument to force reprocessing


        # Run skull stripping as batch job
        #bsub -o logs -e logs mass -in "$image" -dest "$(dirname $image)" \
        #    -ref /project/MRI_Templates/MASS_Templates/WithCerebellum -NOQ -mem 20
        bsub -o logs -e logs singularity run -e -B /project -B /scratch /project/singularity_images/mass_latest.sif \
        -in "$image" -dest "$(dirname $image)" -ref /project/MRI_Templates/MASS_Templates/WithCerebellum -NOQ -mem 20
    done

elif [ "$1" == FLAIR ]; then

    GADG_FLAIR=($(cut -d, -f6 file_list+preproc.csv | grep 'gadgetron' | grep 'FLAIR'))
    printf "There were %s FLAIR scans found.\n" ${#GADG_FLAIR[@]} 

    for image in ${GADG_FLAIR[@]}; do

        if [ $(grep "FL_n4.nii.gz" <<< "$image" | wc -l) == 1 ]; then
            #grep "FL_n4.nii.gz" <<< "$image"
            #echo "Visit 1"
            mprage_pair=$(ls $(dirname "$image") | grep "TFL_n4.nii.gz" | head -n1) # get mprage image pair

            bsub -J reg2
            
            # Insert registration and apply correct mask skullstripping
        elif [ $(grep "FLa_n4.nii.gz" <<< "$image" | wc -l) == 1 ]; then
            
            ls $(dirname "$image") | grep "TFLa_n4.nii.gz"
            # find $(dirname "$image") -name "TFLa_n4.nii.gz"
            #grep "FLa_n4.nii.gz" <<< "$image"
            #echo "Visit 2"
        else
            echo "Not found"
        fi
    done
fi
