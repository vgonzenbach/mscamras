# Instructions from: http://davidroalf.com/script_download/
# 
# AFNI and FSL must be installed and in your PATH environment
# 
# To execute the quality assurance scripts, you will need download the scripts and 
# extract all scripts to the same directory. In addition, you will need the full paths to:
# 
# a) the raw DTI nifti image you wish to analyze (nifti)
# b) corresponding bval file (bval)
# c) corresponding bvec file (bvec)
# d) output path and output file name
# 
# The quality assurance script is then called utilizing the above variables 
# in the following command (all necessary subscripts should run as long as they are in 
# the script folder and neuroimaging tools are in your PATH enviornment):
# 
# /path/to/your/scripts/folder/qa_dti_v1.sh [nifti] [bval] [bvec] [outfile]

module load fsl
module load afni_openmp/20.1 

cd $(dirname $0)/..
ROOT=$(pwd)
mkdir -p results/dti_qa/output/

cd dti/qa/scripts
for img in $(ls $ROOT/data/*/*/dwi/*.nii.gz); do
    fn=${img%%.*} # parameter expansion to eliminate extension in filename

    bsub -o "$ROOT"/logs/qa.log -e "$ROOT"/logs/qa.log ./qa_dti_v1.sh "$fn".nii.gz "$fn".bval "$fn".bvec "$ROOT"/results/dti_qa/output/$(basename -- "$fn")
done