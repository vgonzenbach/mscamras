library(fslr)
library(neurobase)
library(ANTsR)
library(extrantsr)
library(scales)
library(parallel)

##FSL FAST segmentation for GM, WM, and CSF

argv = commandArgs(trailingOnly = TRUE)
t1 = argv[1]
out_dir = argv[2]
out_dir = file.path(out_dir, "FAST")
dir.create(out_dir)

out_file = file.path(out_dir, neurobase::nii.stub(t1, bn = TRUE))
t1_fast = fslr::fast(t1, outfile = out_file, bias_correct = FALSE)
message(sprintf("FAST output saved as %s", out_file))
