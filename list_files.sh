#!/bin/bash
PATIENTS=(01-001 01-002 01-003 02-001 02-002 02-003 03-001 03-002 04-001 04-002 04-003)
SITES=(BWH NIH Penn)

echo "ID,site,img_type,img_source,original" > file_list.csv
for patient in ${PATIENTS[@]}; do
        for site in ${SITES[@]}; do 
            # Fill in lines for onscanner images
            for fname in FLAIR_SAG_VFL_ND.nii.gz FLAIR_SAG_VFL_NDa.nii.gz MPRAGE_SAG_TFL_ND.nii.gz MPRAGE_SAG_TFL_NDa.nii.gz; do
                find /project/mscamras/Data/"$patient"/"$site"/NIFTI/ -name "$fname" &> tmp_raw_find_result.txt 
                sed -i '/No such file or directory/ c\NA' tmp_raw_find_result.txt
                printf "%s,%s,%s,onscanner,%s\n" $patient $site "$(sed 's/\*//g; s/.nii.gz//g' <<< $fname)" "$(head -n1 tmp_raw_find_result.txt)" >> file_list.csv
            done

            # Fill in lines for gadgetron images
            for fname in *FLAIR_SAG_VFL.nii.gz *FLAIR_SAG_VFLa.nii.gz *MPRAGE_SAG_TFL.nii.gz *MPRAGE_SAG_TFLa.nii.gz; do 
                find /project/mscamras/gadgetron/datasets/"$patient"-"$site"/ -name "$fname" &> tmp_gadg_find_result.txt
                sed -i '/No such file or directory/ c\NA' tmp_gadg_find_result.txt
                printf "%s,%s,%s,gadgetron,%s\n" $patient $site "$(sed 's/\*//g; s/.nii.gz//g' <<< $fname)" "$(head -n1 tmp_gadg_find_result.txt)" >> file_list.csv
            done
        done
    done
# delete tmp files
rm tmp_raw_find_result.txt tmp_gadg_find_result.txt
