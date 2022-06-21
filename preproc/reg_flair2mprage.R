library(neurobase)
library(ANTsR)
library(extrantsr)
library(fslr)
library(stringr)

#' Registers flair to mprage
argv = commandArgs(trailingOnly = TRUE)
flair = argv[1]
mprage = argv[2]


print('Computing transformation...')
flair2mprage = antsRegistration(fixed = extrantsr::oro2ants(neurobase::readnii(mprage)), 
                                moving = extrantsr::oro2ants(neurobase::readnii(flair)),
                                typeofTransform = "Rigid",
                                verbose = TRUE)

print('Applying transformation...')                            
flair_reg = antsApplyTransforms(fixed=extrantsr::oro2ants(neurobase::readnii(mprage)), 
                                moving=extrantsr::oro2ants(neurobase::readnii(flair)),
                                transformlist = flair2mprage$fwdtransforms,
                                interpolator ="WelchWindowedSinc",
                                verbose = TRUE)

print('Saving transformed image...')

outdir = file.path(dirname(flair), "reg")
dir.create(outdir)
outpath = file.path(outdir, stringr::str_replace(basename(flair), '.nii.gz', '_reg.nii.gz'))
antsImageWrite(flair_reg, outpath)
print('Registration complete.')