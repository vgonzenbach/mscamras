# N4 correction
module load ANTs

IMAGES=($(cut -d, -f5 file_list.csv))

GADG_IMAGES=($(printf -- '%s\n' "${IMAGES[@]}" | grep gadgetron))

for image in ${GADG_IMAGES[@]}
do 
    bsub -J $image -o logs -e logs N4BiasFieldCorrection -d 3 -i ${image} -o "$(dirname ${image})/$(basename ${image} .nii.gz)_n4.nii.gz"
done