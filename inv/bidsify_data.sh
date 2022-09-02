#!/bin/bash

cd "$(dirname $0)"/..
mkdir -p data

#1 pick relevant files 
#2 translate path to a bids path
#3 make symbolic links

#dest_dir="$1" # destination directory .i.e path with name of the dataset
copy_type="$1" # '--hard' for hard copy or '--sym' for symbolic link
# populate mprages
for f in $(ls /project/mscamras/Data/*/*/NIFTI/* | grep -E 'MPRAGE|FLAIR|DTI' | grep -Ev 'Mono|SAG_T[1-2]|SAG_3D'); do
    
    filename="${f%%.*}"
    ext="${f#*.}"
    
    subj=$(echo "$f" | cut -d/ -f5 | sed 's/-//'g)
    ses=$(echo "$f" | cut -d/ -f6)
    
    # for anatomical images only transfer ND acquisition
    if [[ "$filename" =~ Hopkins ]]; then # Hopkins has no ND-version
        acq='D'
    
    elif [[ "$filename" =~ ND$ || "$filename" =~ NDa$ ||  "$filename" =~ DTI ]]; then 
        acq='ND'
        
    else # exit if site is not Hopkins and images are not distorion corrected (anat w/o 'ND' in filename)
        continue
    fi

    if [ ${filename: -1} == 'a' ]; then # check last character of filename to get visit
        run='02'
    else
        run='01'
    fi

    # translate filepaths to BIDS

    if [[ "$filename" =~ MPRAGE ]]; then
            bids_file=data/sub-"$subj""$ses""$run"/anat/sub-"$subj""$ses""$run"_acq-"$acq"_T1w."$ext"

        elif [[ "$filename" =~ FLAIR ]]; then
            bids_file=data/sub-"$subj""$ses""$run"/anat/sub-"$subj""$ses""$run"_acq-"$acq"_T2w."$ext"

        elif [[ "$filename" =~ DTI ]]; then
            if [[ "$filename" =~ Pa?$|_XPhase_ ]]; then
                dir="XPhase"
            elif [[ "$filename" =~  Aa?$|_AX_ ]]; then
                dir="AX"
            fi
            bids_file=data/sub-"$subj""$ses""$run"/dwi/sub-"$subj""$ses""$run"_acq-"$acq"_dir-"$dir"_dwi."$ext"
    fi
    #echo "$subj" "$ses" "$acq" "$run" "$filename"
    mkdir -p $(dirname $bids_file)

    # decide what kind of copy to do based on 2nd parameter
    if [ $copy_type == "--sym" ]; then
        echo "Linking $f to $bids_file"
        ln -s $f $bids_file

    elif [ $copy_type == "--hard" ]; then
        echo "Copying $f to $bids_file"
        cp $f $bids_file

    fi
    unset -v subj ses acq run
done

echo '{
  "Name": "MS CAMRAS: Studying Site effects in MS Neuroimaging",
  "BIDSVersion": "1.9.6",
  "Authors": ["Penn Statistics in Imaging and Visualization Endeavor (PennSIVE)", "Organized by Virgilio Gonzenbach"]
}' > data/dataset_description.json

# Correct .json on Hopkins data 
~/.conda/envs/mscamras/bin/python inv/check_json_dti.py

# Make folder for pipelines
mkdir -p data/derivatives
