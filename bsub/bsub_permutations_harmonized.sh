#!/bin/bash
cd $(dirname $0)/..

# Handle arguments
n=$1
if [[ $# -eq 0 ]]; then echo "Error: Enter number of cores for each job"; exit 1; fi

# extract and transform data
bsub -J permute -o logs/permutations.log -e logs/permutations.log -n $n Rscript eval/site_effect_permutation_testing.R results/avg_tensor_by_roi_wide_harmonized.csv
bsub -J permute -o logs/permutations.log -e logs/permutations.log -n $n Rscript eval/site_effect_permutation_testing.R results/avg_tensor_by_roi_wide_no_Hopkins_harmonized.csv