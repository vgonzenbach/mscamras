library(neurobase)
library(ANTsR)
library(extrantsr)
library(fslr)

# Applies brain mask from mprage to registered flair

argv = commandArgs(trailingOnly = TRUE)
image = argv[1]
brain_mask = argv[2]
out_dir = argv[3]

brain = neurobase::readnii(image) * neurobase::readnii(brain_mask)

output_path = file.path(out_dir, stringr::str_replace(basename(image), '.nii.gz', '_brain.nii.gz'))
neurobase::writenii(brain, output_path)
sprintf("Output saved to %s", output_path)