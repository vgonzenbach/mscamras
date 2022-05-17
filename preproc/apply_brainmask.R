library(neurobase)
library(ANTsR)
library(extrantsr)
library(fslr)

# Applies brain mask from mprage to registered flair

argv = commandArgs(trailingOnly = TRUE)
reg_flair = argv[1]
brain_mask = argv[2]

flair_brain = neurobase::readnii(reg_flair) * neurobase::readnii(brain_mask)

output_path = file.path(dirname(reg_flair), "..", "mass",
                        stringr::str_replace(basename(reg_flair), '.nii.gz', '_brain.nii.gz'))
neurobase::writenii(flair_brain, output_path)
sprintf("Output saved to %s", output_path)