module load fsl

cd $(dirname $0)/..
# invert mimosa masks
#find data/v5/derivatives/mimosa -name *mask.nii.gz | xargs -n1 bash -c 'fslmaths $0 -binv $(echo $0 | sed 's/desc-n4regmasked/desc-inverted/g')'
# zero out mimosa regions
for inv_mimosa in $(find data/v5/derivatives/mimosa -name *desc-inverted*mask.nii.gz); do 
    sub=$(echo $inv_mimosa | cut -d/ -f5)

    for seg in $(find data/v5/derivatives -name "${sub}*dseg.nii.gz" -or -name  "${sub}*_all_none_firstseg.nii.gz" -or -name "${sub}*_seg.nii.gz" | grep -Ev "qsiprep|sanslesion"); do
        bsub -e sanslesions.log -o sanslesions.log fslmaths $seg -mas $inv_mimosa $(echo $seg | sed 's/desc-masked/desc-sanslesion/g')
    done
done
