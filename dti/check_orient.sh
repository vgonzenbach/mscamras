#!/bin/bash
# Check orientation for all images
module load fsl
get_orient () {
    img=$1
    echo $(fslhd $img | grep -E "qform_.orient" | cut -d$'\t' -f2 | cut -c-1 - | awk '{print}' ORS='')
}
cd $(dirname $0)/..

function syntax {
    echo "$(basename $0) [-v 0-4] [-h]"
    echo "  -v <data-version>  Version of the dataset according to changes made"
    echo "                  to metadata (see inv/bidsify_dataset.sh)"
}

# Read in options
while getopts ":v:h" opt; do
  case ${opt} in
    v )
      if [[ "${OPTARG}" =~ ^[0-4]$ ]]; then
        data_version="${OPTARG}"
      else
        echo "Invalid argument for -v: ${OPTARG}. Version number must be between 0 and 4." >&2
        exit 1
      fi
      ;;
    h )
      syntax
      exit 0
      ;;
    \? )
      echo "Invalid option: -${OPTARG}. Use -h for help." >&2
      exit 1
      ;;
    : )
      echo "Option -${OPTARG} requires an argument. Use -h for help." >&2
      exit 1
      ;;
  esac
done

for img in $(find data/v${data_version} -name *nii.gz); do
    # parse site from img path
    site=$(echo "$img" | grep -Eo -m1 "ses-[a-zA-Z]+" | head -n1)
    # use method to get LPI or RPI orientation
    orient=$(get_orient $img)
    # parse modality from path
    mod=$(basename $img | grep -Eo "T1w|T2w|dwi")
    # use fsl orient to output RADIOLOGICAL OR NEUROLOGICAL
    conv=$(fslorient $img)

    printf "%s\t%s\t%s\t%s\t\n"  ${site[*]} ${orient[*]} $mod $conv
done