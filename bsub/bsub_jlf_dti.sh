#!/bin/bash
# Submits jobs for jlf_seg of qsiprep-processed T1w images
cd $(dirname $0)/..
if [ $# -eq 0 ]; then
    echo "choose mode 'WMGM' or 'thal'" && exit 1   
fi
mode=$1 # mode can be 'WMGM' or 'thal'
mkdir -p logs/jlfseg_$mode data/v5/derivatives/jlfseg_$mode
for t1 in $(find data/v5/derivatives/qsiprep -path '*masked_T1w.nii.gz' -not -path '*MNI*'); do
    
    sub=$(echo $t1 | cut -d/ -f5)
    out=$(echo ${t1%%.*} | sed "s/qsiprep/jlfseg_$mode/g ; s/T1w/space-T1w/g")_dseg.nii.gz
    
    bsub -J jlfseg_$mode -oo logs/jlfseg_$mode/$sub -eo logs/jlfseg_$mode/$sub Rscript seg/jlf.R --mode $mode -n 10 $t1 $out

done

echo '{
    "Name": "JLF Segmentation output",
    "BIDSVersion": "1.1.1",
    "PipelineDescription": {
        "Name": "JointLabelFusion Segmentation in Native Space (JLF_SEG)"
    }
}' > data/v5/derivatives/jlfseg_$mode/dataset_description.json
