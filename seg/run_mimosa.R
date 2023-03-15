library(neurobase)
library(fslr)
library(WhiteStripe)
library(mimosa)

# Read in arguments (paths)
message("Reading in data...")
argv = commandArgs(trailingOnly = TRUE)

t1 = neurobase::readnii(argv[1])
flair = neurobase::readnii(argv[2])
brain_mask = neurobase::readnii(argv[3])
outpath = argv[4]

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

message('Smoothing probability map...')
pmap_smooth = fslr::fslsmooth(probability_map, sigma = 1.25, mask=tissue_mask, retimg=TRUE, smooth_mask=TRUE) # probability map
neurobase::writenii(pmap_smooth, outpath)
message("Probability map saved.")
