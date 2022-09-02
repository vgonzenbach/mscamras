cd $(dirname $0)/..
NCORES=32
bsub -n $NCORES -o logs/qsiprep.log -e logs/qsiprep.log singularity run --cleanenv -B /project/mscamras -B /home/vgonzenb/mscamras -B /appl/freesurfer-7.1.1/license.txt:/opt/freesurfer/license.txt \
    /project/singularity_images/qsiprep_0.16.0RC3.sif /home/vgonzenb/mscamras/data /home/vgonzenb/mscamras/data/derivatives participant \
    --output-resolution 2.2 \
    --fs-license-file /opt/freesurfer/license.txt \
    --distortion-group-merge average \
    --nthreads $NCORES