#!/bin/bash
cd $(dirname $0)/..

# resample dtifit results to fit segmentation masks
bsub -J extract -n 500 -oo logs/etl.log -eo logs/etl.log Rscript seg/extract_data.R 
bsub -J transform -w extract -ti -o logs/etl.log -e logs/etl.log Rscript seg/transform_data.R 
