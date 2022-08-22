#!/bin/bash
# Check orientation for all images
module load fsl
get_orient () {
    img=$1
    fslhd $img | grep -E "qform_.orient" | cut -d$'\t' -f2 | while read s; do
        # orient+=(${s:0:1})
        echo ${s:0:1}
    done 
}
cd $(dirname $0)/..
for img in $(find data -name *nii.gz); do

    site=$(echo "$img" | grep -Eo -m1 "ses-[a-zA-Z]+" | head -n1)
    orient=$(echo $(get_orient $img) | sed -e "s/ //g")
    mod=$(basename $img | grep -Eo "T1w|T2w|dwi")
    conv=$(fslorient $img)

    printf "%s\t%s\t%s\t%s\t\n"  ${site[*]} ${orient[*]} $mod $conv
done