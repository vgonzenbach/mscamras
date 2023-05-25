#!/bin/bash
cd $(dirname $0)/..

# Handle argument
n=$1
if [[ $# -eq 0 ]]; then echo "Error: Enter number of cores for each job"; exit 1; fi

# extract and transform data
bsub -J extract -n $n -oo logs/etl.log -eo logs/etl.log Rscript seg/extract_data.R
bsub -J transform -w extract -ti -o logs/etl.log -e logs/etl.log Rscript seg/transform_data.R 
