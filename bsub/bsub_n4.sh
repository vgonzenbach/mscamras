# N4 correction
module load ANTs

for image in $(ls /project/mscamras/gadgetron/datasets-new/*/*/*.nii.gz); do 
    
    out_image=$(dirname $image)/n4/$(basename $image .nii.gz)_n4.nii.gz
    
    if [ ! -e "$out_image" ]; then
        mkdir -p $(dirname $image)/n4
        bsub -J "$image" -o logs/n4.log -e logs/n4.log N4BiasFieldCorrection -d 3 -i "$image" -o "$out_image"
    fi
done