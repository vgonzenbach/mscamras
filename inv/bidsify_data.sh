#!/bin/bash
if [[ $# -eq 0 ]]; then
    echo "No arguments supplied"
    exit
fi
data_version=$1
# First (and only) argument specifies modifications to be made to the data and/or metadata
# v0: Copy all data
# v1: Copy the metadata without modifying file contents but remove incomplete subjects
# v2: Modify Hopkins .json files
# v3: Modify .bvec and .bval files for non-Hopkins data
# v4: Modify NIH .json files
# See docs/check_data_<version>.html for more info

cd "$(dirname $0)"/..
data_path=data/${data_version}
mkdir -p ${data_path}

# copy files into bids format
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
            bids_file=${data_path}/sub-"$subj""$ses""$run"/anat/sub-"$subj""$ses""$run"_acq-"$acq"_T1w."$ext"

        elif [[ "$filename" =~ FLAIR ]]; then
            bids_file=${data_path}/sub-"$subj""$ses""$run"/anat/sub-"$subj""$ses""$run"_acq-"$acq"_T2w."$ext"

        elif [[ "$filename" =~ DTI ]]; then
            if [[ "$filename" =~ Pa?$|_XPhase_ ]]; then
                dir="XPhase"
            elif [[ "$filename" =~  Aa?$|_AX_ ]]; then
                dir="AX"
            fi
            bids_file=${data_path}/sub-"$subj""$ses""$run"/dwi/sub-"$subj""$ses""$run"_acq-"$acq"_dir-"$dir"_dwi."$ext"
    fi
    #echo "$subj" "$ses" "$acq" "$run" "$filename"
    mkdir -p $(dirname $bids_file)

    echo "Copying $f to $bids_file"
    cp $f $bids_file

    unset -v subj ses acq run
done

## create top-level .json
echo '{
  "Name": "MS CAMRAS: Studying Site effects in MS Neuroimaging",
  "BIDSVersion": "1.9.6",
  "Authors": ["Penn Statistics in Imaging and Visualization Endeavor (PennSIVE)", "Organized by Virgilio Gonzenbach"]
}' > ${data_path}/dataset_description.json

# Make folder for pipelines
mkdir -p ${data_path}/derivatives

# extract number in version number
version_number=$(sed 's/v//g' <<< $data_version)

# Delete 02001NIH01 and 02001NIH02 since DTI missing for version 0 or greater
if [[ ${version_number} -ge 1 ]]; then
    rm -r ${data_path}/sub-02001NIH0*
fi

# Correct .json on Hopkins data  for version 1 or greater
if [[ ${version_number} -ge 2 ]]; then
    .venv/bin/python3 inv/fix_json.py --fix-hopkins ${data_path}
fi

# Modify .bvec and .bval files for non-Hopkins for v2 or greater
if [[ ${version_number} -ge 3 ]]; then
    for site in NIH Penn BWH; do
        bvals=($(ls ${data_path}/*${site}*/dwi/*.bval))
        bvecs=($(ls ${data_path}/*${site}*/dwi/*.bvec))
        
        # chose which file to keep for the site
        the_one_bval=${bvals[0]}
        the_one_bvec=${bvecs[0]}

        # iterate over a sequence from 1 to (length of array - 1)
        for i in $(seq $(expr ${#bvecs[@]} - 1)); do # - 1
            cp $the_one_bval ${bvals[i]}
            cp $the_one_bvec ${bvecs[i]}
        done

    done 
fi
# Modify NIH data
if [[ ${version_number} -ge 4 ]]; then
    .venv/bin/python3 inv/fix_json.py --fix-nih ${data_path}
fi

# Modify Hopkins subject
if [[ ${version_number} -ge 5 ]]; then
	.venv/bin/python3 <<-EOF
		import nibabel as nb
		first_img = nb.load("data/v5/sub-02002Hopkins02/dwi/sub-02002Hopkins02_acq-D_dir-XPhase_dwi.nii.gz")
		second_img = nb.load("data/v5/sub-02002Hopkins02/dwi/sub-02002Hopkins02_acq-D_dir-AX_dwi.nii.gz")
		fixed_second_img = nb.Nifti1Image(second_img.get_fdata(), first_img.affine, header=first_img.header)
		fixed_second_img.to_filename("data/v5/sub-02002Hopkins02/dwi/sub-02002Hopkins02_acq-D_dir-AX_dwi.nii.gz")
	EOF
    # make bvecs match for this image
    cp data/v5/sub-02002Hopkins02/dwi/sub-02002Hopkins02_acq-D_dir-AX_dwi.bvec data/v5/sub-02002Hopkins02/dwi/sub-02002Hopkins02_acq-D_dir-XPhase_dwi.bvec
fi
echo "Database ${data_version} copied"