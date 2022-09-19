cd $(dirname $0)/..
for subject in $(python -c "import sys; from bids import BIDSLayout; layout = BIDSLayout('data'); subjects = layout.get_subjects(); sys.stdout.write(' '.join(subjects))"); do
    bsub -J qsiprep -o logs/qsiprep/sub-$subject.log -e logs/qsiprep/sub-$subject.log singularity run --cleanenv -B /project/mscamras -B /home/vgonzenb/mscamras -B /appl/freesurfer-7.1.1/license.txt:/opt/freesurfer/license.txt \
        /project/singularity_images/qsiprep_0.16.0RC3.sif /home/vgonzenb/mscamras/data /home/vgonzenb/mscamras/data/derivatives participant \
        --participant-label $subject \
        --output-resolution 2.2 \
        --fs-license-file /opt/freesurfer/license.txt \
        --distortion-group-merge average
done