library(neurobase)
library(fslr)
library(WhiteStripe)
library(mimosa)

# Read in arguments (paths)
message("Reading in data...")
argv = commandArgs(trailingOnly = TRUE)
subj_dir = file.path(dirname(argv[1]), "..")
out_dir = file.path(subj_dir, "mimosa", neurobase::nii.stub(basename(argv[1])))
t1 = neurobase::readnii(argv[1])
flair = neurobase::readnii(argv[2])
brain_mask = neurobase::readnii(argv[3])

# Run WhiteStripe (intensity normalization)
message('Running WhiteStripe normalization...')
t1_ws = WhiteStripe::whitestripe_norm(t1, indices = whitestripe(t1, "T1", stripped=TRUE)$whitestripe.ind)
flair_ws = WhiteStripe::whitestripe_norm(flair, indices = whitestripe(flair, "T2", stripped=TRUE)$whitestripe.ind)

# Prepare data for mimosa
message('Preparing data for mimosa...')
mimosa_dat = mimosa::mimosa_data(brain_mask = brain_mask, 
                                 FLAIR = flair_ws, 
                                 T1 = t1_ws)

mimosa_df = mimosa_dat$mimosa_dataframe
cand_voxels = mimosa_dat$top_voxels
tissue_mask = mimosa_dat$tissue_mask

# Apply trained model
load("/project/Melissa_stuff/mimosa/mimosa_model.RData")

message('Fitting mimosa model...')
predictions = predict(mimosa_model,
                      newdata = mimosa_df,
                      type = 'response')
probability_map = neurobase::niftiarr(cand_voxels, 0)
probability_map[cand_voxels == 1] = predictions


system(sprintf('mkdir %s/mimosa', subj_dir))
system(sprintf('mkdir %s', out_dir))

message('Smoothing probability map...')
pmap_smooth = fslr::fslsmooth(probability_map, sigma = 1.25, mask=tissue_mask, retimg=TRUE, smooth_mask=TRUE) # probability map
neurobase::writenii(pmap_smooth, file.path(out_dir, "prob_map.nii.gz"))

thr = 0.2

message('Binarizing mask...')
lesion_binary_mask = (pmap_smooth >= thr) 

out_path = file.path(out_dir, sprintf("bin_mask_%s.nii.gz", thr))
neurobase::writenii(lesion_binary_mask, out_path)

sprintf("Binary mask saved to %s", out_path)
