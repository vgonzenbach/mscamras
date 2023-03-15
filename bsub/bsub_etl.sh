#!/bin/bash
cd $(dirname $0)/..

# extract and transform data
bsub -J extract -n 500 -oo logs/etl.log -eo logs/etl.log Rscript seg/extract_data.R 
bsub -J transform -w extract -ti -o logs/etl.log -e logs/etl.log Rscript seg/transform_data.R 
