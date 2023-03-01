#!/bin/bash
# Run qsi prep by subject on different versions of dataset

# Set working directory
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

if [ -z "${data_version}" ]; then
  echo "Error data_version to run $(basename $0) not specified. Use -h argument for help" >&2
  exit 1
fi

version_dir=v${data_version}
logs_dir=logs/qsiprep/${version_dir}
mkdir -p $logs_dir

for subject in $(.venv/bin/python3 -c "import sys; from bids import BIDSLayout; layout = BIDSLayout('data/${version_dir}'); subjects = layout.get_subjects(); sys.stdout.write(' '.join(subjects))"); do
    bsub -J qsiprep_${version_dir} -o $logs_dir/sub-$subject.log -e $logs_dir/sub-$subject.log singularity run --cleanenv -B /project/mscamras -B /home/vgonzenb/mscamras -B /appl/freesurfer-7.1.1/license.txt:/opt/freesurfer/license.txt \
        /project/singularity_images/qsiprep_0.16.0RC3.sif /home/vgonzenb/mscamras/data/${version_dir} /home/vgonzenb/mscamras/data/${version_dir}/derivatives participant \
        --participant-label $subject \
        --output-resolution 2.2 \
        --fs-license-file /opt/freesurfer/license.txt \
        --distortion-group-merge average
done