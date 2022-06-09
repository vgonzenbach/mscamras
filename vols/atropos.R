library(fslr)
library(neurobase)
library(ANTsR)
library(extrantsr)
library(scales)
library(parallel)

#ATROPOS for GM, WM, and CSF

argv = commandArgs(trailingOnly = TRUE)
t1 = argv[1]
out_dir = argv[2]
out_dir = file.path(out_dir, "Atropos")
dir.create(out_dir)

img = neurobase::readnii(t1)
otropos_img = extrantsr::otropos(img, make_mask = TRUE)
seg = otropos_img$segmentation
out_file = file.path(outdir, sprintf("%s_atropos_seg.nii.gz", neurobase::nii.stub(t1, bn = TRUE)))
neurobase::writenii(seg, out_file)
message(sprintf("Atropos segmentation saved as %s", out_file))
