library(fslr)
library(neurobase)
library(argparser)
##FSL FAST segmentation for GM, WM, and CSF
p <- arg_parser("Run FAST segmentation")
p <- add_argument(p, "T1w", help = 'T1-weighted image to run segmentation.')
argv <- parse_args(p)

out_file = argv$T1w |> 
        neurobase::nii.stub() |> 
        stringr::str_replace('qsiprep', 'fast')
dir.create(dirname(out_file), recursive = TRUE)

t1_fast = fslr::fast(argv$T1w, outfile = out_file, bias_correct = FALSE)
message(sprintf("FAST output saved as %s", out_file))
