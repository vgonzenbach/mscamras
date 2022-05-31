#!/bin/bash
module load ANTs2/2.2.0-111

# Script takes a skull-stripped T1 image as argument
t1=$1
dir="$(dirname $t1)"/../JLF_thal/"$(basename $t1 .nii.gz)"

declare -a atlas
declare -a thalamus

# Fill arrays
for i in {0..9}; do
	atlas[$i]="${dir}/atlas_to_t1/jlf_template_reg$(expr $i + 1).nii.gz"
	thalamus[$i]="${dir}/seg_to_t1/jlf_thal_reg$(expr $i + 1).nii.gz"
done

antsJointFusion -t $t1 -g ${atlas[*]} -l ${thalamus[*]} -b 4.0 -c 0 -o "${dir}/fused_thal_mask.nii.gz" -v 0