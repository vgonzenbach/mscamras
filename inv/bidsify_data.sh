#!/bin/bash

cd "$(dirname $0)"/..
mkdir -p data

#1 pick relevant files 
#2 translate path to a bids path
#3 make symbolic links

dest_dir="$1" # destination directory .i.e path with name of the dataset
copy_type="$2" # '--hard' for hard copy or '--sym' for symbolic link
# populate mprages
for f in $(ls /project/mscamras/Data/*/*/NIFTI/* | grep -E 'MPRAGE|FLAIR|DTI' | grep -Ev 'Mono|SAG_T[1-2]|SAG_3D'); do
    
    filename="${f%%.*}"
    ext="${f#*.}"
    
    subj=$(echo "$f" | cut -d/ -f5 | sed 's/-//'g)
    ses=$(echo "$f" | cut -d/ -f6)
    
    if [ ${filename: -1} == 'a' ]; then # check last character of filename to get visit
        run='02'
    else
        run='01'
    fi

    if [[ "$filename" =~ ND$ || "$filename" =~ NDa$ ]]; then
        acq='ND'
    else
        acq='D'
    fi

    # translate filepaths to BIDS

    if [[ "$filename" =~ MPRAGE ]]; then
        bids_file=data/sub-"$subj"/ses-"$ses"/anat/sub-"$subj"_ses-"$ses"_acq-"$acq"_run-"$run"_T1w."$ext"

    elif [[ "$filename" =~ FLAIR ]]; then
        bids_file=data/sub-"$subj"/ses-"$ses"/anat/sub-"$subj"_ses-"$ses"_acq-"$acq"_run-"$run"_T2w."$ext"

    elif [[ "$filename" =~ DTI ]]; then
        acq=''
        if [[ "$filename" =~ Pa?$|_XPhase_ ]]; then
            dir="XPhase"
        elif [[ "$filename" =~  Aa?$|_AX_ ]]; then
            dir="AX"
        fi

        bids_file="$dest_dir"/sub-"$subj"/ses-"$ses"/dwi/sub-"$subj"_ses-"$ses"_dir-"$dir"_run-"$run"_dwi."$ext"
    fi

    echo "$subj" "$ses" "$acq" "$run" "$filename"
    mkdir -p $(dirname $bids_file)

    # decide what kind of copy to do based on 2nd parameter
    if [ $copy_type == "--sym" ]; then
        ln -s $f $bids_file

    elif [ $copy_type == "--hard" ]; then
        cp $f $bids_file

    fi
    unset -v subj ses acq run
done
