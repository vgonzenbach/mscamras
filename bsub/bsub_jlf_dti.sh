#!/bin/bash
# Submits jobs for jlf_seg of qsiprep-processed T1w images
cd $(dirname $0)/..
shopt -s extglob

for img in $(ls data/derivatives/qsiprep/sub-*/anat/sub-+([0123456789])_desc-preproc_T1w.nii.gz ); do
    
    outdir=$(dirname $img | sed 's/qsiprep/jlf_seg/g')
    mkdir -p $outdir

    outimg=${outdir}/$(basename $img .nii.gz | grep -Eo "sub-[0-9]+")_space-T1w_dseg.nii.gz

    bsub Rscript seg/jlf.R $img $outimg
    echo Running JLF on $img
done

echo '{
    "Name": "JLF Segmentation output",
    "BIDSVersion": "1.1.1",
    "PipelineDescription": {
        "Name": "JointLabelFusion Segmentation in Native Space (JLF_SEG)"
    }
}' > data/derivatives/jlf_seg/dataset_description.json

