#!/bin/bash
module load ANTs2/2.2.0-111

# Script takes a skull-stripped T1 image as argument
mode=$(echo $1 | tr A-Z
t1=$2
dir="$(dirname $t1)"/../JLF_"$mode"/"$(basename $t1 .nii.gz)"

declare -a atlas
declare -a wmgm

# Fill arrays
for i in {0..9}; do
	atlas[$i]="${dir}/atlas_to_t1/jlf_template_reg$(expr $i + 1).nii.gz"
	seg[$i]="${dir}/seg_to_t1/jlf_${mode}_reg$(expr $i + 1).nii.gz"
done

echo 'Running antsJointFusion...'
antsJointFusion -t $t1 -g ${atlas[*]} -l ${seg[*]} -b 4.0 -c 0 -o "${dir}/fused_${mode}_seg.nii.gz" -v 0