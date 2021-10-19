#!/bin/bash
PATIENTS=(01-001 01-002 01-003 02-001 02-002 02-003 03-001 03-002 04-001 04-002 04-003)
FNAMES=(*FLAIR_SAG_VFLa.*nii.gz *FLAIR_SAG_VFL.*nii.gz *MPRAGE_SAG_TFL.*nii.gz *MPRAGE_SAG_TFLa.*nii.gz)
SITES=(BWH Hopkins NIH Penn)

for patient in ${PATIENTS[*]}
    do
        for site in ${SITES[*]}
        do 
            for fname in ${FNAMES[*]}
            do 
                find /project/mscamras/Data/"$patient"/"$site"/NIFTI/ -name "$fname" &>> file_list.txt
                find /project/mscamras/gadgetron/datasets/"$patient"-"$site"/ -name "${fname}" &>> file_list.txt
            done;
        done;
    done;