#!/bin/bash
cd $(dirname $0)/..

# extract and transform data
bsub -J permute -o logs/permutations.log -e logs/permutations.log -n 500 Rscript eval/site_effect_permutation_testing.R avg_tensor_by_roi_wide.csv