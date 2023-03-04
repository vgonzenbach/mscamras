#!/bin/bash
# Run DTIfit on data preprocessed by qsiprep
module load fsl
cd $(dirname $0)/..

data_version=v4

for dwi in $(find data/${data_version}/derivatives/qsiprep -path '**preproc_dwi.nii.gz'); do
    mask=$(echo $dwi | sed 's/preproc_dwi/brain_mask/g')
    bval=${dwi%%.*}.bval # use parameter expansion to reassign extension
    bvec=${dwi%%.*}.bvec
    cni=$(echo ${dwi%%.*} | sed 's/space-T1w_desc-preproc_dwi/confounds/g').tsv

    sub=$(echo $dwi | grep -Eo sub-[A-Za-z0-9]+ | grep -Eo [0-9]+ | head -n1)
   
    out=data/${data_version}/derivatives/dtifit/sub-$sub/dwi/$(basename $dwi _dwi.nii.gz)
    mkdir -p $(dirname $out)

    bsub -J dtifit_$sub -oo logs/dtifit//${data_version}/$sub.log -eo logs/dtifit/${data_version}/$sub.log dtifit --data=$dwi \
        --out=$out \
        --mask=$mask \
        --bvals=$bval \
        --bvecs=$bvec 
    bsub -w dtifit_$sub -ti 
done

echo '{
    "Name": "dtifit output",
    "BIDSVersion": "1.1.1",
    "PipelineDescription": {
        "Name": "FSL DTIFIT"
    }
}' > data/derivatives/dtifit/dataset_description.json