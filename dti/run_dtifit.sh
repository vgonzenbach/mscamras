#!/bin/bash
# Run DTIfit on data preprocessed by qsiprep
module load fsl
cd $(dirname $0)/..

data_version=v5

for dwi in $(find data/${data_version}/derivatives/qsiprep -path '**preproc_dwi.nii.gz'); do
    mask=$(echo $dwi | sed 's/preproc_dwi/brain_mask/g')
    bval=${dwi%%.*}.bval # use parameter expansion to reassign extension
    bvec=${dwi%%.*}.bvec


    sub=$(echo $dwi | grep -Eo sub-[A-Za-z0-9]+ | grep -Eo [0-9]+ | head -n1)
   
    out=data/${data_version}/derivatives/dtifit/sub-$sub/dwi/$(basename $dwi .nii.gz)
    mkdir -p $(dirname $out)

    bsub -J dtifit_$sub -oo logs/dtifit/${data_version}/$sub.log -eo logs/dtifit/${data_version}/$sub.log dtifit --data=$dwi \
        --out=$out \
        --mask=$mask \
        --bvals=$bval \
        --bvecs=$bvec 
    # copy file with AD name 
    bsub -w dtifit_$sub -ti cp ${out}_L1.nii.gz ${out}_AD.nii.gz
    bsub -w dtifit_$sub -ti fslmaths ${out}_L2.nii.gz -add ${out}_L3.nii.gz -div 2 ${out}_RD.nii.gz
done

echo '{
    "Name": "dtifit output",
    "BIDSVersion": "1.1.1",
    "PipelineDescription": {
        "Name": "FSL DTIFIT"
    }
}' > data/${data_version}/derivatives/dtifit/dataset_description.json