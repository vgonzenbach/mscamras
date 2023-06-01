#!/bin/bash
cd $(dirname $0)/..

# harmonize
bsub -J combat -o logs/combat.log -e logs/combat.log Rscript eval/harmonize_sites.R avg_tensor_by_roi_wide.csv
bsub -J combat -o logs/combat.log -e logs/combat.log Rscript eval/harmonize_sites.R avg_tensor_by_roi_wide_no_Hopkins.csv