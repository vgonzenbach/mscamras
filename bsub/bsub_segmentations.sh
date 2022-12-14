#!/bin/bash
module load fsl
module load ANTs2/2.2.0-111

# JLF for WM GM
bsub -q "cceb_normal" -J jlfwmgm -n 25 -o logs/jlfwmgm.log -e logs/jlfwmgm.log Rscript vols/JLF\ Grey\ and\ White\ Matter\ Volumes.R 

# JLF for Thalamus
bsub -q "cceb_normal" -J jlfthal -n 25 -o logs/jlfthal.log -e logs/jlfthal.log Rscript vols/JLF_thal_register_templates.R 

# Atropos for GM, WM, and CSF
#bsub -m "pennsive01 pennsive03 pennsive04 pennsive05 silver01 amber04" -J atropos -n 62 -o logs/atropos.log -e logs/atropos.log Rscript vols/atropos_segmentation.R 

# FSL FIRST deep grey structures
#bsub -m "pennsive01 pennsive03 pennsive04 pennsive05 silver01 amber04" -J FIRST -n 62 -o logs/first.log -e logs/first.log Rscript vols/fsl_first.R

# FSL FAST for GM, WM, and CSF
#bsub -m "pennsive01 pennsive03 pennsive04 pennsive05 silver01 amber04" -J FAST -n 62 -o logs/fast.log -e logs/fast.log Rscript vols/fsl_fast.R