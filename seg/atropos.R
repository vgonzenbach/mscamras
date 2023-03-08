library(stringr)
library(neurobase)
library(ANTsR)
library(extrantsr)
library(argparser)

#ATROPOS for GM, WM, and CSF
p <- arg_parser("Run Atropos segmentation")
p <- add_argument(p, "T1w", help = 'T1-weighted image to run segmentation.')
argv <- parse_args(p)

# set up
out_file = stringr::str_replace(argv$T1w, 'qsiprep', 'atropos') |>
    stringr::str_replace('desc-preproc_T1w', 'space-orig_dseg')
dir.create(dirname(out_file), recursive = TRUE)

# compute result
img = neurobase::readnii(argv$T1w)
otropos_img = extrantsr::otropos(img, make_mask = TRUE)
seg = otropos_img$segmentation
# write result
neurobase::writenii(seg, out_file)
message(sprintf("Atropos segmentation saved as %s", out_file))
