library(neurobase)
library(ANTsR)
library(extrantsr)
library(fslr)
library(stringr)

#' Registers onscanner t1 to gadgetron, applying transform to mask w NN interpolation
argv = commandArgs(trailingOnly = TRUE)
t1 = argv[1]
onscanner_t1 = argv[2]
mask = argv[3] 


print('Computing transformation...')
onscanner2gadgetron = antsRegistration(fixed = extrantsr::oro2ants(neurobase::readnii(t1)), 
                                       moving = extrantsr::oro2ants(neurobase::readnii(onscanner_t1)),
                                       typeofTransform = "Rigid",
                                       verbose = TRUE)

print('Applying transformation...')                            
reg_mask = antsApplyTransforms(fixed=extrantsr::oro2ants(neurobase::readnii(t1)), 
                                moving=extrantsr::oro2ants(neurobase::readnii(mask)),
                                transformlist = onscanner2gadgetron$fwdtransforms,
                                interpolator = "nearestNeighbor",
                                verbose = TRUE)

print('Saving transformed image...')

outdir = file.path(dirname(t1), "brain")
dir.create(outdir)
outpath = file.path(outdir, stringr::str_replace(basename(t1), '.nii.gz', '_brainmask.nii.gz'))
antsImageWrite(reg_mask, outpath)
print('Registration complete.')