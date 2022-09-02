#!/bin/bash
# Run DTIfit on data preprocessed by qsiprep
module load fsl
cd $(dirname $0)/..
pwd

for dwi in $(ls data/derivatives/qsiprep/sub-*/dwi/*dwi.nii.gz); do
    mask=$(echo $dwi | sed 's/preproc_dwi/brain_mask/g')
    bval=${dwi%%.*}.bval # use parameter expansion to reassign extension
    bvec=${dwi%%.*}.bvec
    cni=$(echo ${dwi%%.*} | sed 's/space-T1w_desc-preproc_dwi/confounds/g').tsv

    sub=$(echo $dwi | grep -Eo sub-[A-Za-z0-9]+ | grep -Eo [0-9]+ | head -n1)
    #ses=$(echo $dwi | grep -Eo ses-[A-Za-z]+ | grep -Eo [0-9]+ | head -n1)
    out=data/derivatives/dtifit/sub-$sub/dwi/$(basename $dwi _dwi.nii.gz)
    mkdir -p $(dirname $out)
    bsub dtifit --data=$dwi \
        --out=$out \
        --mask=$mask \
        --bvals=$bval \
        --bvecs=$bvec #\ 
        #--cni=$cni # TODO:figure out what to do with confound.tsv file
done

echo '{
    "Name": "dtifit output",
    "BIDSVersion": "1.1.1",
    "PipelineDescription": {
        "Name": "FSL DTIFIT"
    }
}' > data/derivatives/dtifit/dataset_description.json