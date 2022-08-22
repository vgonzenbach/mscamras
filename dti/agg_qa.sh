#!/bin/bash
# Agreagate
cd $(dirname $0)/..

cols=(modulename version inputfile clipcount tsnr gmean drift outmax outmean outlist meanABSrms meanRELrms maxABSrms  maxRELrms) 
mkdir -p results/dti_qa/
echo "${cols[*]}" | tr ' ' '\t' > results/dti_qa/dti_qa.tsv # print array elements with tab as separator
for result in $(find results/dti_qa/output/ * -name *dwi); do

    lines=()
    while read -r line; do
        #echo $i: $(echo $line | cut -d' ' -f1)
        lines+=($(echo $line | cut -d' ' -f2 | sed 's/outcount//g'))
    ((++i))
    done < $result

    echo "${lines[*]}" | tr ' ' '\t' >> results/dti_qa/dti_qa.tsv

done